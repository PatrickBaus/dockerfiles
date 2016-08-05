#!/bin/sh

# Bash "strict mode"
# Exit if any return value is non zero (-e), any variables are not reclared (-u)
# and do not mask errors in pipelines (using |) (-o pipefail)
set -euo pipefail

BUILD_DEPS="gnupg tar"
apk add -U $BUILD_DEPS

# Create folder for the nextcloud installation
mkdir -p /var/www/nextcloud

NEXTCLOUD_TARBALL="nextcloud-${NEXTCLOUD_VERSION}.tar.bz2"
NEXTCLOUD_TARBALL="owncloud-${NEXTCLOUD_VERSION}.tar.bz2"

# Create a temporary folder, which will later be removed
temp_dir="$(mktemp -d)"
cd ${temp_dir}
echo -n "Downloading source..."
wget -q "https://download.owncloud.org/community/${NEXTCLOUD_TARBALL}" && \
wget -q "https://download.owncloud.org/community/${NEXTCLOUD_TARBALL}.sha256" && \
wget -q "https://download.owncloud.org/community/${NEXTCLOUD_TARBALL}.asc" && \
echo "Done."

#  wget -q https://download.nextcloud.com/server/releases/${NEXTCLOUD_TARBALL} && \
#  wget -q https://download.nextcloud.com/server/releases/${NEXTCLOUD_TARBALL}.sha256 && \
#  wget -q https://download.nextcloud.com/server/releases/${NEXTCLOUD_TARBALL}.asc && \
#  wget -q https://nextcloud.com/nextcloud.asc && \

echo -n "Verifying integrity of ${NEXTCLOUD_TARBALL}..."
CHECKSUM_STATE=$(echo -n $(sha256sum -c "${NEXTCLOUD_TARBALL}.sha256") | tail -c 2)
if [ "${CHECKSUM_STATE}" != "OK" ]; then
  echo "Warning! Checksum does not match!"
  exit 1
fi
echo "Done."

echo -n "Verifying authenticity of ${NEXTCLOUD_TARBALL}..."
export GNUPGHOME=${temp_dir}
gpg --keyserver ha.pool.sks-keyservers.net --recv-keys "${GPG_NEXTCLOUD}"
gpg --batch --verify "${NEXTCLOUD_TARBALL}.asc" "${NEXTCLOUD_TARBALL}"
unset GNUPGHOME
echo "Done."

echo -n "Unpacking source..."
cd ${temp_dir}
tar xjf "${NEXTCLOUD_TARBALL}" --strip 1 -C /var/www/nextcloud
echo "Done."

echo -n "Cleaning up..."
apk del $BUILD_DEPS
rm -rf /var/cache/apk/* ${temp_dir}
echo "Done."
