#!/bin/sh

# Bash "strict mode"
# Exit if any return value is non zero (-e), any variables are not reclared (-u)
# and do not mask errors in pipelines (using |) (-o pipefail)
set -euo pipefail

# For a list of required modules see:
# https://docs.nextcloud.com/server/9/admin_manual/installation/source_installation.html
NEXTCLOUD_DEPS="\
  php5 \
  php5-ctype \
  php5-dom \
  php5-gd \
  php5-iconv \
  php5-json \
  php5-posix \
  php5-zip \
  php5-zlib \
  php5-xml \
  php5-xmlreader
"
# Database connector
NEXTCLOUD_DEPS="${NEXTCLOUD_DEPS} \
  php5-pdo_mysql
"
# Recommended packages
NEXTCLOUD_DEPS="${NEXTCLOUD_DEPS} \
  php5-curl \
  php5-bz2 \
  php5-intl \
  php5-mcrypt \
  openssl \
  ca-certificates \
  php5-openssl
"
# Required for specific apps
NEXTCLOUD_DEPS="${NEXTCLOUD_DEPS} \
  php5-ldap \
  php5-exif
"
# Packages for enhanced performance
NEXTCLOUD_DEPS="${NEXTCLOUD_DEPS} \
  php5-apcu \
  php5-opcache \
  php5-fpm \
"
# To colour the bash use the following command:
# echo -e "${COLOUR}foo\e[0m"
COLOUR='\e[1;93m'

echo -ne "${COLOUR}Installing PHP and extensions for Nextcloud...\e[0m"
apk add -U ${NEXTCLOUD_DEPS}
echo -e "${COLOUR}Done.\e[0m"

# Clean up
echo -ne "${COLOUR}Cleaning up...\e[0m"
rm -rf /var/cache/apk/*
echo -e "${COLOUR}Done.\e[0m"
