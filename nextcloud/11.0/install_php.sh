#!/bin/sh

# Bash "strict mode"
# Exit if any return value is non zero (-e), any variables are not reclared (-u)
# and do not mask errors in pipelines (using |) (-o pipefail)
set -euo pipefail

# For a list of required modules see:
# https://docs.nextcloud.com/server/11/admin_manual/installation/source_installation.html
NEXTCLOUD_DEPS="\
  php7 \
  php7-ctype \
  php7-dom \
  php7-gd \
  php7-iconv \
  php7-json \
  php7-mbstring
  php7-posix \
  php7-zip \
  php7-zlib \
  php7-xml \
  php7-xmlreader \
  php7-xmlwriter \
  php7-session \
  php7-simplexml
"

# Optional dependencies for the nextcloud occ script
NEXTCLOUD_DEPS="${NEXTCLOUD_DEPS} \
  php7-pcntl
"

# Database connector
NEXTCLOUD_DEPS="${NEXTCLOUD_DEPS} \
  php7-pdo_mysql
"
# Recommended packages
NEXTCLOUD_DEPS="${NEXTCLOUD_DEPS} \
  php7-curl \
  php7-bz2 \
  php7-intl \
  php7-mcrypt \
  openssl \
  ca-certificates \
  php7-openssl
"
# Required for specific apps
NEXTCLOUD_DEPS="${NEXTCLOUD_DEPS} \
  php7-ldap \
  php7-exif
"
# Packages for enhanced performance
NEXTCLOUD_DEPS="${NEXTCLOUD_DEPS} \
  php7-apcu \
  php7-opcache \
  php7-fpm
"
# To colour the bash use the following command:
# echo -e "${COLOUR}foo\e[0m"
COLOUR='\e[1;93m'

echo -e "${COLOUR}Installing PHP and extensions for Nextcloud...\e[0m"
apk add -U ${NEXTCLOUD_DEPS}
# Add symlink from php to php7, because it is not created by default, because PHP 7 is not the default in alpine
#ln -s /usr/bin/php7 /usr/bin/php
#ln -s /usr/sbin/php-fpm7 /usr/sbin/php-fpm
echo -e "${COLOUR}Done.\e[0m"

# Clean up
echo -ne "${COLOUR}Cleaning up...\e[0m"
rm -rf /var/cache/apk/*
echo -e "${COLOUR}Done.\e[0m"
