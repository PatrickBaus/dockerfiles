#!/bin/sh

# Bash "strict mode"
# Exit if any return value is non zero (-e), any variables are not reclared (-u)
# and do not mask errors in pipelines (using |) (-o pipefail)
set -euo pipefail

BUILD_DEPS="build-base openssl ca-certificates file gnupg libtool"
apk add -U $BUILD_DEPS

# Get the number of CPU cores
nproc=$(grep -c ^processor /proc/cpuinfo 2>/dev/null || 1)

LIBICONV_TARBALL="libiconv-${LIBICONV_VERSION}.tar.gz"

# The key that was used to sign the libiconv source
GPG_KEY="1736 90D4 963E 5FC4 6917  7FA7 C71A 4C65 F059 B1D1"

# download source to a temporary folder, which will later be removed
temp_dir="$(mktemp -d)"
cd ${temp_dir}
echo -n "Downloading source for libiconv..."
wget -q https://ftp.gnu.org/pub/gnu/libiconv/${LIBICONV_TARBALL}
wget -q https://ftp.gnu.org/pub/gnu/libiconv/${LIBICONV_TARBALL}.sig
echo "Done."

# Verify the download
echo -n "Verifying authenticity of ${LIBICONV_TARBALL}..."
export GNUPGHOME=${temp_dir}
gpg --keyserver ha.pool.sks-keyservers.net --recv-keys "${GPG_KEY}"
gpg --verify "${temp_dir}/${LIBICONV_TARBALL}.sig"
unset GNUPGHOME
echo "Done."

echo -n "Unpacking source..."
cd ${temp_dir}
tar -xzf "${LIBICONV_TARBALL}"
mv libiconv-${LIBICONV_VERSION} libiconv
echo "Done."

# remove original iconv file, which comes with musl-utils
rm /usr/bin/iconv || true

# Comment this warning, because gets is not supported anyway
sed -i 's!_GL_WARN_ON_USE (gets, "gets is a security hole - use fgets instead");!/* _GL_WARN_ON_USE (gets, "gets is a security hole - use fgets instead"); */!' ${temp_dir}/libiconv/srclib/stdio.in.h

# Configure, make and install libiconv
echo -n "Configuring and making..."
cd ${temp_dir}/libiconv/
./configure --prefix=/usr/local && make -j${nproc} && make install
echo "Done."

# Clean up
echo -n "Cleaning up..."
apk del $BUILD_DEPS
rm -rf /var/cache/apk/* ${temp_dir}
echo "Done."
