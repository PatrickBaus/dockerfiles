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
ulimit -n 1024

sanityCheck() {
  # Check if there is an existing database but without a config
  # Exclude DB_CONFIG.example from the list of files, because it was installed by the package.
  if [ -n "$(ls -A /var/lib/openldap/openldap-data | egrep -v '^DB_CONFIG.example$')" ] \
     && [ -f '/var/lib/openldap/openldap-data/INIT_DONE' ]; then
    echo 'Error: Existing database found, but no config was found. Restore the config and import from backup!'
    echo -e "Data directory contains: \n$(ls -A /var/lib/openldap/openldap-data | egrep -v '^DB_CONFIG.example$')"
    exit 1
  fi

  # First do some sanity checks
  if [ -z "${SLAPD_ROOT_PASSWORD:+x}" ]; then
    echo -n >&2 'Error: Container not configured and SLAPD_ROOT_PASSWORD not set. '
    echo >&2 'Did you forget to add -e SLAPD_ROOT_PASSWORD=... ?'
    exit 1
  fi

  if [ -z "${SLAPD_DOMAIN:+x}" ]; then
    echo -n >&2 'Error: Container not configured and SLAPD_DOMAIN not set. '
    echo >&2 'Did you forget to add -e SLAPD_DOMAIN=... ?'
    exit 1
  fi
}

addSchemas() {
  # Add additional schemas
  if [ -n "${SLAPD_ADDITIONAL_SCHEMAS:+x}" ]; then
    IFS=','
    schemas=$SLAPD_ADDITIONAL_SCHEMAS
    for schema in ${schemas}; do
      schema="${schema}.schema"
      schema_file="/etc/openldap/schema/${schema}"
      echo "Adding schema '${schema}' to database..."
      if [ -e "${schema_file}" ]; then
        sed -i "/nis.schema/a include		${schema_file}" /etc/openldap/slapd.conf
      else
        echo -n >&2 "Error: Cannot find schema ${schema_file}. "
        echo >&2 'Did you forget to copy it to schema/ ?'
        exit 1
      fi
    done
    unset IFS
  fi
}

createInitialDatabase() {
  # Create a new database file
  cp /etc/openldap/slapd.conf.default /etc/openldap/slapd.conf
  echo -e "# one 0.25 GB cache\nset_cachesize 0 268435456 1" > /var/lib/openldap/openldap-data/DB_CONFIG
  # Generate the base string from the domain
  base_string="$(echo dc=$(echo ${SLAPD_DOMAIN} | sed 's/^\.//; s/\./,dc=/g'))"
  sed -i "s|\${SLAPD_DOMAIN}|$base_string|g" /etc/openldap/slapd.conf

  addSchemas

  chown -R "${LDAP_USER}:${LDAP_GROUP}" /var/lib/openldap/openldap-data
  chown -R "${LDAP_USER}:${LDAP_GROUP}" /etc/openldap/slapd.conf

  slapd -u "${LDAP_USER}" -g "${LDAP_GROUP}" -h 'ldapi:///'
  killall slapd

  # Create a secure password hash for the root account
  # We use standard Linux CRYPT hashes
  password_hash=`slappasswd -h {CRYPT} -c '$6$%.16s' -s "${SLAPD_ROOT_PASSWORD}"`
  # Escape the hash for use with sed
  password_hash=${password_hash//\//\\\/}
  # Insert the password into the config file
  sed -i "s|rootpw.*|rootpw		${password_hash}|g" /etc/openldap/slapd.conf

  # Since Openldap version 2.3 all settings are stored in an online configuration
  # which is stored in slapd.d/. It is much easier to configure
  # the old config file slapd.conf, so we use slaptest to convert the file

  slaptest -v -f /etc/openldap/slapd.conf -F /etc/openldap/slapd.d/ 2>&1 >/dev/null

  # Set permissions
  chown -R "${LDAP_USER}:${LDAP_GROUP}" /etc/openldap/slapd.d
  chmod -R 0750 /etc/openldap/slapd.d
}

importData() {
  if [ -n "${SLAPD_DATA_IMPORTS:+x}" ]; then
    echo '------------------------------------------------'
    echo 'Importing data files into database 1...'
    IFS=','
    imports=$SLAPD_DATA_IMPORTS;

    for import in ${imports}; do
      import_file="/etc/openldap/data/${import}.ldif"
      echo '------------------------------------------------'
      echo "** Importing data file '${import}.ldif' to database..."
      if [ -e "${import_file}" ]; then
        slapadd -v -n1 -l "${import_file}"
        echo '** Done.'
      else
        echo -n >&2 "Error: Cannot find data file ${import_file}. "
        echo >&2 'Did you forget to copy it to database/ ?'
        exit 1
      fi
    done
    unset IFS
  fi
}

addModules() {
  # The database must be up and running to use this function
  if [ -n "${SLAPD_ADDITIONAL_MODULES:+x}" ]; then
    IFS=','
    modules=$SLAPD_ADDITIONAL_MODULES;

    for module in ${modules}; do
      module_file="/etc/openldap/modules/${module}.ldif"
      echo '------------------------------------------------'
      echo "** Adding module '${module}' to database..."
      if [ -e "${module_file}" ]; then
         ldapmodify -Q -Y EXTERNAL -H ldapi:/// -f "${module_file}" 2>&1 >/dev/null
        #ldapadd -v -n0 -l "${module_file}"
        echo '** Done.'
      else
        echo -n >&2 "Error: Cannot find module ${module_file}. "
        echo >&2 'Did you forget to copy it to modules/ ?'
        exit 1
      fi
    done
    unset IFS
  fi
}

# Run this on first start
if [ ! -f '/etc/openldap/slapd.d/INIT_DONE' ]; then
  echo -e "${COLOUR}ERR Cannot find OpenLDAP configuration. Starting setup...\e[0m"
  sanityCheck

  # Clean the config and database folder.
  # There might be remmants of a previously failed install attempt.
  rm -rf /etc/openldap/slapd.d/*
  rm -rf /var/lib/openldap/openldap-data/*

  echo 'Generating database...'
  createInitialDatabase
  echo 'Done.'

  # Generate the base string from the domain
  base_string="$(echo dc=$(echo ${SLAPD_DOMAIN} | sed 's/^\.//; s/\./,dc=/g'))"

  # Append domain name to the organization
  SLAPD_ORGANIZATION="${SLAPD_ORGANIZATION:-${SLAPD_DOMAIN}}"

  # Configure base directory
  sed -i "s|\${SLAPD_DOMAIN}|$base_string|g" /etc/openldap/data/base.ldif
  sed -i "s|dc: \${SLAPD_DC}|dc: $(echo ${SLAPD_DOMAIN} | sed -n 's/^\([A-Za-z0-9_-]\+\).*/\1/p')|g" /etc/openldap/data/base.ldif
  sed -i "s|o: \${SLAPD_ORGANIZATION}|o: ${SLAPD_ORGANIZATION}|g" /etc/openldap/data/base.ldif
  sed -i "s|description: \${SLAPD_DESCRIPTION}|description: ${SLAPD_DESCRIPTION}|g" /etc/openldap/data/base.ldif

  # Start database to use ldapadd instead of slapadd
  slapd -u "${LDAP_USER}" -g "${LDAP_GROUP}" -h 'ldapi:///'

  echo '------------------------------------------------'
  echo 'Adding modules...'
  addModules
  echo 'Done adding modules.'

  # Import data files
  # These files will be added using sladadd
  # If you import a backup at this point, make sure that the
  # corresponding config is imported as well
  importData

  # Set permissions
  echo -n "Setting permission to '${LDAP_USER}:${LDAP_GROUP}'..."
  chown -R "${LDAP_USER}:${LDAP_GROUP}" /etc/openldap/slapd.d
  chmod 700 /var/lib/openldap/openldap-data
  echo 'Done.'

  echo -n 'Reindexing database...'
  chown -R "${LDAP_USER}:${LDAP_GROUP}" /etc/openldap/slapd.d
  su-exec "${LDAP_USER}" slapindex
  echo 'Done.'

  # close the slapd session
  killall slapd

  # Your LDAP directory is now ready to be populated
  echo '# DO NOT REMOVE THIS FILE! It is used to determine the container initialization state.' > /etc/openldap/slapd.d/INIT_DONE
  echo '# DO NOT REMOVE THIS FILE! It is used to determine the container initialization state.' > /var/lib/openldap/openldap-data/INIT_DONE
  echo -e "${COLOUR}Finished setting up OpenLDAP.\e[0m"
else
  slapd_configs_in_env=$(env | grep 'SLAPD_' || true)

  if [ -n "${slapd_configs_in_env}" ]; then
    echo -e "${COLOUR}WARN Container already configured, for security reasons remove the SLAPD_* environment variables\e[0m"
  fi
fi

exec "$@"
