#!/bin/sh

# Bash "strict mode"
# Exit if any return value is non zero (-e), any variables are not reclared (-u)
# and do not mask errors in pipelines (using |) (-o pipefail)
set -euo pipefail

# Set dfault variables
SERVER_DESCRIPTION="${SERVER_DESCRIPTION:-My LDAP Server}"
LDAP_SERVER="${LDAP_SERVER:-openldap}"
LDAP_PORT="${LDAP_PORT:-389}"
LDAP_BIND_DN="${LDAP_BIND_DN:-cn=root,dc=example,dc=net}"

sed -i "s|'server','name','My LDAP Server'|'server','name','${SERVER_DESCRIPTION}'|g" /usr/share/webapps/phpldapadmin/config/config.php
sed -i "s|'server','host','127.0.0.1'|'server','host','${LDAP_SERVER}'|g" /usr/share/webapps/phpldapadmin/config/config.php
sed -i "s|'server','port',389|'server','port',${LDAP_PORT}|g" /usr/share/webapps/phpldapadmin/config/config.php
sed -i "s|'login','bind_id','cn=Manager,dc=example,dc=com'|'login','bind_id','${LDAP_BIND_DN}'|g" /usr/share/webapps/phpldapadmin/config/config.php

# Remove the Sourceforge logo in the lower right corner, because we don't want external 3rd party content in our local network
# We do this by removing a case block from functions.php. The 'logo' block will be cut out using sed
sed -i "/case 'logo':/,/return/d" /usr/share/webapps/phpldapadmin/lib/functions.php

exec "$@"
