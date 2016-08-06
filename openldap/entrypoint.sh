#!/bin/sh

# Bash "strict mode"
# Exit if any return value is non zero (-e), any variables are not reclared (-u)
# and do not mask errors in pipelines (using |) (-o pipefail)
set -euo pipefail

# To colour the bash use the following command:
# echo -e "${COLOUR}foo\e[0m"
COLOUR='\e[1;93m'

LDAP_USER="ldap"
LDAP_GROUP="ldap"

# When not limiting the open file descritors limit, the memory consumption of
# slapd is absurdly high. See https://github.com/docker/docker/issues/8231
ulimit -n 8192

# Run this on first start
# Make sure the config folder does *not* exist or is empty
if [ ! -d "/etc/openldap/slapd.d" ] || [ -z "$(ls -A /etc/openldap/slapd.d)" ]; then
  echo "Could not find OpenLDAP configuration. Starting setup..."
  # First do some sanity checks
  if [ -z "${SLAPD_PASSWORD+x}" ]; then
    echo -n >&2 "Error: Container not configured and SLAPD_PASSWORD not set. "
    echo >&2 "Did you forget to add -e SLAPD_PASSWORD=... ?"
    exit 1
  fi

  if [ -z "${SLAPD_DOMAIN+x}" ]; then
    echo -n >&2 "Error: Container not configured and SLAPD_DOMAIN not set. "
    echo >&2 "Did you forget to add -e SLAPD_DOMAIN=... ?"
    exit 1
  fi

  # Check if there is an existing database but without a config
  # Exclude DB_CONFIG.example from the list of files, because it was installed by the package.
  if [ -n "$(ls -A /var/lib/openldap/openldap-data | egrep -v '^DB_CONFIG.example$')" ]; then
    echo 'Error: Existing database found, but no config was found. Restore the config and import from backup!'
    echo -e "Data directory contains: \n$(ls -A /var/lib/openldap/openldap-data | egrep -v '^DB_CONFIG.example$')"
    exit 1
  fi

  # Create a config folder
  mkdir -p /etc/openldap/slapd.d

  # Add additional schemas
  if [ -n "${SLAPD_ADDITIONAL_SCHEMAS+x}" ]; then
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
  # We use standard Linux CRYPT hashes
  password_hash=`slappasswd -h {CRYPT} -c '$6$%.16s' -s "${SLAPD_PASSWORD}"`
  # Escape the hash for use with sed
  password_hash=${password_hash//\//\\\/}
  # Insert the password into the config file
  sed -i "s|rootpw.*|rootpw		${password_hash}|g" /etc/openldap/slapd.conf

  # Generate the base string from the domain
  base_string="$(echo dc=$(echo ${SLAPD_DOMAIN} | sed 's/^\.//; s/\./,dc=/g'))"

  # Append domain name to the organization
  SLAPD_ORGANIZATION="${SLAPD_ORGANIZATION:-${SLAPD_DOMAIN}}"

  # Configure base directory
  sed -i "s|dc=example,dc=net|$base_string|g" /etc/openldap/slapd.conf
  sed -i "s|dc=example,dc=net|$base_string|g" /etc/openldap/database/base.ldif
  sed -i "s|dc: example|dc: $(echo ${SLAPD_DOMAIN} | sed -n 's/^\([A-Za-z0-9_-]\+\).*/\1/p')|g" /etc/openldap/database/base.ldif
  sed -i "s|o: Example|o: $SLAPD_ORGANIZATION|g" /etc/openldap/database/base.ldif
  sed -i "s|description: My LDAP Server|description: $SLAPD_DESCRIPTION|g" /etc/openldap/database/base.ldif

  # Create a new database file
  echo -n 'Data directory is empty, generating database...'
  cp /var/lib/openldap/openldap-data/DB_CONFIG.example /var/lib/openldap/openldap-data/DB_CONFIG
  chown -R "${LDAP_USER}:${LDAP_GROUP}" /var/lib/openldap/openldap-data

  # Run slapd once to generate a database
  slapd -u "${LDAP_USER}" -g "${LDAP_GROUP}" >/dev/null 2>&1
  killall slapd
  echo 'Done.'

  # Since Openldap version 2.3 all settings are stored in an online configuration
  # which is stored in slapd.d/. Since it is much easier to configure
  # the old config file slapd.conf, we use slaptest to convert the file
  slaptest -f /etc/openldap/slapd.conf -F /etc/openldap/slapd.d/

  if [ -n "${SLAPD_ADDITIONAL_MODULES+x}" ]; then
    IFS=","
    modules=$SLAPD_ADDITIONAL_MODULES;

    for module in ${modules}; do
      module_file="/etc/openldap/modules/${module}.ldif"
      echo "Adding module ${module} to database..."
      if [ -e "${module_file}" ]; then
        slapadd -n0 -l "${module_file}"
      else
        echo -n >&2 "Error: Cannot find module ${module_file}. "
        echo >&2 "Did you forget to copy it to modules/ ?"
        exit 1
      fi
    done
    unset IFS
  fi

  # Add root nodes
  echo '------------------------------------------------'
  echo 'Adding root nodes...'
  slapadd -v -l /etc/openldap/database/base.ldif
  if [ -n "${SLAPD_ADDITIONAL_IMPORTS+x}" ]; then
    IFS=","
    imports=$SLAPD_ADDITIONAL_IMPORTS;

    for import in ${imports}; do
      import_file="/etc/openldap/database/${import}.ldif"
      if [ -e "${import_file}" ]; then
        echo '------------------------------------------------'
        echo "Adding data file ${import}.ldif to database..."
        slapadd -v -l "${import_file}"
      else
        echo -n >&2 "Error: Cannot find data file ${import_file}. "
        echo >&2 "Did you forget to copy it to database/ ?"
        exit 1
      fi
    done
    unset IFS
  fi

  # Set permissions
  echo -n "Setting permission to ${LDAP_USER}:${LDAP_GROUP}..."
  chown -R "${LDAP_USER}:${LDAP_GROUP}" /etc/openldap/slapd.d
  chmod 700 /var/lib/openldap/openldap-data
  echo "Done."

  echo -n "Reindexing database..."
  chown -R "${LDAP_USER}:${LDAP_GROUP}" /etc/openldap/slapd.d
  su "${LDAP_USER}" -s /bin/sh -c slapindex
  echo "Done."

  # Your LDAP directory is now ready to be populated
  echo "Finished setting up OpenLDAP."

else
  slapd_configs_in_env=$(env | grep 'SLAPD_' || true)

  if [ -n "${slapd_configs_in_env}" ]; then
    echo -e "${COLOUR}WARN Container already configured, for security reasons remove the SLAPD_* environment variables\e[0m"
  fi
fi

exec "$@"
