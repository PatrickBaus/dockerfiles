#!/bin/sh

# Bash "strict mode"
# Exit if any return value is non zero (-e), any variables are not reclared (-u)
# and do not mask errors in pipelines (using |) (-o pipefail)
set -euo pipefail

chown -R $UID:$GID /etc/nginx /var/log/nginx /run/nginx /www /tmp
chmod -R 700 /etc/nginx/certs

exec "$@"
