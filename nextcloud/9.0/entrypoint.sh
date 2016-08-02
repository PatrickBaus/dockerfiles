#!/bin/sh

# Bash "strict mode"
# Exit if any return value is non zero (-e), any variables are not reclared (-u)
# and do not mask errors in pipelines (using |) (-o pipefail)
set -euo pipefail

mkdir -p /tmp/fastcgi /tmp/client_body

# Set the permissions of the container
echo -n 'Settings permissions for the config/data folders...'
chown -R nginx /var/www/nextcloud/config/
chown -R nginx /var/www/nextcloud/data/
chown -R nginx /var/www/nextcloud/apps_persisted
echo 'Done.'

exec "$@"
