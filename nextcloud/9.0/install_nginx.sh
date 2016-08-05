#!/bin/sh

# Bash "strict mode"
# Exit if any return value is non zero (-e), any variables are not reclared (-u)
# and do not mask errors in pipelines (using |) (-o pipefail)
set -euo pipefail

# To colour the bash use the following command:
# echo -e "${COLOUR}foo\e[0m"
COLOUR='\e[1;93m'

echo -ne "${COLOUR}Installing Nginx...\e[0m"
apk add -U nginx

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
