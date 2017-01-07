#!/bin/sh

# Bash "strict mode"
# Exit if any return value is non zero (-e), any variables are not reclared (-u)
# and do not mask errors in pipelines (using |) (-o pipefail)
set -euo pipefail

# To colour the bash use the following command:
# echo -e "${COLOUR}foo\e[0m"
COLOUR='\e[1;93m'

apk add -U --virtual=build-dependencies gnupg tar

# Create folder for the nextcloud installation
mkdir -p /var/www/nextcloud

NEXTCLOUD_TARBALL="nextcloud-${NEXTCLOUD_VERSION}.tar.bz2"
#NEXTCLOUD_TARBALL="owncloud-${NEXTCLOUD_VERSION}.tar.bz2"

# Create a temporary folder, which will later be removed
temp_dir="$(mktemp -d)"
cd ${temp_dir}
echo -ne "${COLOUR}Downloading source...\e[0m"
wget -q https://download.nextcloud.com/server/releases/${NEXTCLOUD_TARBALL}
wget -q https://download.nextcloud.com/server/releases/${NEXTCLOUD_TARBALL}.sha256
wget -q https://download.nextcloud.com/server/releases/${NEXTCLOUD_TARBALL}.asc
echo -e "${COLOUR}Done.\e[0m"

echo -ne "${COLOUR}Verifying integrity of ${NEXTCLOUD_TARBALL}...\e[0m"
CHECKSUM_STATE=$(echo -n $(sha256sum -c "${NEXTCLOUD_TARBALL}.sha256") | tail -c 2)
if [ "${CHECKSUM_STATE}" != "OK" ]; then
  echo -e "${COLOUR}Warning! Checksum does not match!"
  exit 1
fi
echo -e "${COLOUR}Done.\e[0m"

echo -e "${COLOUR}Verifying authenticity of ${NEXTCLOUD_TARBALL}...\e[0m"
export GNUPGHOME=${temp_dir}
gpg --keyserver ha.pool.sks-keyservers.net --recv-keys "${GPG_NEXTCLOUD}"
gpg --batch --verify "${NEXTCLOUD_TARBALL}.asc" "${NEXTCLOUD_TARBALL}"
unset GNUPGHOME
echo -e "${COLOUR}Done.\e[0m"

echo -ne "${COLOUR}Unpacking source...\e[0m"
cd ${temp_dir}
tar xjf "${NEXTCLOUD_TARBALL}" --strip 1 -C /var/www/nextcloud
echo -e "${COLOUR}Done.\e[0m"

echo -ne "${COLOUR}Cleaning up...\e[0m"
apk del build-dependencies
rm -rf /var/cache/apk/* ${temp_dir}
echo -e "${COLOUR}Done.\e[0m"
