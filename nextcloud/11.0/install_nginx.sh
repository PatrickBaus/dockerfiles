#!/bin/sh

# Bash "strict mode"
# Exit if any return value is non zero (-e), any variables are not reclared (-u)
# and do not mask errors in pipelines (using |) (-o pipefail)
set -euo pipefail

# To colour the bash use the following command:
# echo -e "${COLOUR}foo\e[0m"
COLOUR='\e[1;93m'
# THe ids used by nginx, this will be replaced by the ones set in the Dockerfile
OLD_UID=101
OLD_GID=101
USER="nginx"
USER_GROUP=${USER}

echo -e "${COLOUR}Installing Nginx...\e[0m"
apk add -U nginx

# Change user/group to UID and GID set in the Dockerfile
echo -e "${COLOUR}Changing user and group...\e[0m"
deluser nginx
addgroup -g ${GID} ${USER_GROUP}
adduser -D -S -u ${UID} -h /var/lib/nginx -s /sbin/nologin -g ${USER} -G ${USER_GROUP} ${USER}

echo -ne "${COLOUR}Changing owner and permissions for old uid/gid files...\e[0m"
find / -user ${OLD_UID} -exec chown ${USER} {} \;
find / -group ${OLD_GID} -exec chgrp ${USER_GROUP} {} \;

# The latest version of nginx stores its pid in /run/nginx/
mkdir -p /run/nginx

# forward request and error logs to docker log collector
ln -sf /dev/stdout /var/log/nginx/access.log
ln -sf /dev/stderr /var/log/nginx/error.log
echo -e "${COLOUR}Done.\e[0m"

# Clean up
echo -ne "${COLOUR}Cleaning up...\e[0m"
rm -rf /var/cache/apk/*
echo -e "${COLOUR}Done.\e[0m"
