#!/bin/sh

# When not limiting the open file descritors limit, the memory consumption of
# slapd is absurdly high. See https://github.com/docker/docker/issues/8231
ulimit -n 8192

SLAPD_CONFIG_FOLDER='/etc/openldap/slapd.d'

set -e
  # Run this on first start
  # Make sure the config folder does *not* exist or is empty
  if [ ! -d "$SLAPD_CONFIG_FOLDER" ] || [ -z "$(ls -A ${SLAPD_CONFIG_FOLDER})" ]; then
    # First do some sanity checks
    if [[ -z "$SLAPD_PASSWORD" ]]; then
      echo -n >&2 "Error: Container not configured and SLAPD_PASSWORD not set. "
      echo >&2 "Did you forget to add -e SLAPD_PASSWORD=... ?"
      exit 1
    fi

    if [[ -z "$SLAPD_DOMAIN" ]]; then
      echo -n >&2 "Error: Container not configured and SLAPD_DOMAIN not set. "
      echo >&2 "Did you forget to add -e SLAPD_DOMAIN=... ?"
      exit 1
    fi

    # Check if there is an existing database but without a config
    if [ -n "$(ls -A /var/lib/openldap/openldap-data | egrep -v '^DB_CONFIG.example$')" ]; then
      echo 'Error: Existing database found, but no config was found. Restore the config and import from backup!'
      echo -e "Data directory contains: \n$(ls -A /var/lib/openldap/openldap-data | egrep -v '^DB_CONFIG.example$')"
      exit 1
    fi


    # Create a config folder
    mkdir -p /etc/openldap/slapd.d

    # Add additional schemas
    if [[ -n "$SLAPD_ADDITIONAL_SCHEMAS" ]]; then
        IFS=','
        schemas=$SLAPD_ADDITIONAL_SCHEMAS
        for schema in ${schemas}; do
          schema="${schema}.schema"
          schema_file="/etc/openldap/schema/${schema}"
          echo "Adding schema ${schema} to database..."
          if [ -e "${schema_file}" ]; then
            sed -i "/nis.schema/a include		${schema_file}" /etc/openldap/slapd.conf
          else
            echo -n >&2 "Error: Cannot find schema ${schema_file}. "
            echo >&2 "Did you forget to copy it to schema/ ?"
            exit 1
          fi
        done
        unset IFS
    fi

    # Create a secure password hash for the root account
    password_hash=`slappasswd -h {CRYPT} -c '$6$%.16s' -s "${SLAPD_PASSWORD}"`
    # Escape the hash for use with sed
    password_hash=${password_hash//\//\\\/}
    password_hash=${SLAPD_PASSWORD}
    # Insert the password into the config file
    sed -i "s|rootpw.*|rootpw		${password_hash}|g" /etc/openldap/slapd.conf

    # Generate the base string from the domain
    dc_string=''
    IFS='.'
    odc=''
    dc_parts=$SLAPD_DOMAIN
    for dc_part in ${dc_parts}; do
      [ -z "${dc_string}" ] && odc="${dc_part}"
        dc_string="${dc_string},dc=${dc_part}"
    done
    unset IFS
    # Remove leading ','
    base_string="${dc_string:1}"

    # Append domain name to the organization
    SLAPD_ORGANIZATION="${SLAPD_ORGANIZATION:-${SLAPD_DOMAIN}}"

    # Configure base directory
    sed -i "s|dc=example,dc=net|$base_string|g" /etc/openldap/slapd.conf
    sed -i "s|dc=example,dc=net|$base_string|g" /etc/openldap/modules/base.ldif
    sed -i "s|dc: example|dc: $odc|g" /etc/openldap/modules/base.ldif
    sed -i "s|o: Example|o: $SLAPD_ORGANIZATION|g" /etc/openldap/modules/base.ldif
    sed -i "s|description: My LDAP Server|description: $SLAPD_DESCRIPTION|g" /etc/openldap/modules/base.ldif

    # Check if we need to install the default database.
    # Exclude DB_CONFIG.example from the list of files, because it was installed by the package.
    echo -n 'Data directory is empty, generating database...'
    cp /var/lib/openldap/openldap-data/DB_CONFIG.example /var/lib/openldap/openldap-data/DB_CONFIG
    chown -R ldap:ldap /var/lib/openldap/openldap-data
    chmod 700 /var/lib/openldap/openldap-data

    slapd -u ldap -g ldap >/dev/null 2>&1
    killall slapd
    echo 'Done.'

    slaptest -f /etc/openldap/slapd.conf -F /etc/openldap/slapd.d/
    # Add root nodes
    echo 'Adding root nodes...'
    # No need to add -F, beause we have set this in OPTS
    slapadd -v -l /etc/openldap/modules/base.ldif

    chown -R ldap:ldap /etc/openldap/slapd.d
    su ldap -s /bin/sh -c slapindex

    if [[ -n "$SLAPD_ADDITIONAL_MODULES" ]]; then
      IFS=","
      modules=$SLAPD_ADDITIONAL_MODULES;

      for module in "${modules}"; do
        module_file="/etc/openldap/modules/${module}.ldif"
        echo "Adding module ${module} to database..."
        if [ -e "${module_file}" ]; then
          # No need to add -F, beause we have set this in OPTS
          slapadd -n0 -l "${module_file}"
        else
          echo -n >&2 "Error: Cannot find module ${module_file}. "
          echo >&2 "Did you forget to copy it to modules/ ?"
          exit 1
        fi
      done
      unset IFS
    fi

  else
    slapd_configs_in_env=`env | grep 'SLAPD_'`

    if [ -n "${slapd_configs_in_env:+x}" ]; then
        echo "Info: Container already configured, therefore ignoring SLAPD_xxx environment variables"
    fi
fi


exec "$@"
