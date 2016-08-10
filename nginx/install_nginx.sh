#!/bin/sh

# Bash "strict mode"
# Exit if any return value is non zero (-e), any variables are not reclared (-u)
# and do not mask errors in pipelines (using |) (-o pipefail)
set -euo pipefail

# Get the number of CPU cores
nproc=${BUILD_CORES-$(grep -c ^processor /proc/cpuinfo 2>/dev/null || 1)}

LIBRESSL_TARBALL="libressl-${LIBRESSL_VERSION}.tar.gz"
NGINX_TARBALL="nginx-${NGINX_VERSION}.tar.gz"
# To colour the bash use the following command:
# echo -e "${COLOUR}foo\e[0m"
COLOUR='\e[1;93m'
BUILD_DEPS=" \
    build-base \
    linux-headers \
    file \
    ca-certificates \
    automake \
    autoconf \
    git \
    tar \
    libtool \
    pcre-dev \
    zlib-dev \
    binutils \
    gnupg \
"

echo -ne "${COLOUR}Installing build dependencies...\e[0m"
apk -U add ${BUILD_DEPS} \
    pcre \
    zlib \
    libgcc \
    libstdc++ \
    su-exec \
    openssl \
    bind-tools
echo -e "${COLOUR}Done.\e[0m"

# Create a temporary folder for the sources, which will later be removed
temp_dir="$(mktemp -d)"
cd ${temp_dir}
echo -ne "${COLOUR}Downloading source for libbrotli...\e[0m"
git clone https://github.com/bagder/libbrotli --depth=1
echo -e "${COLOUR}Done.\e[0m"
echo -ne "${COLOUR}Compiling libbrotli...\e[0m"
cd libbrotli
./autogen.sh
./configure 
make -j${nproc}
make install
echo -e "${COLOUR}Done."

cd ${temp_dir}
echo -ne "${COLOUR}Downloading source for libbrotli nginx module...\e[0m"
git clone https://github.com/google/ngx_brotli --depth=1
echo -e "${COLOUR}Done.\e[0m"

cd ${temp_dir}
echo -ne "${COLOUR}Downloading source for libressl...\e[0m"
wget -q "http://ftp.openbsd.org/pub/OpenBSD/LibreSSL/${LIBRESSL_TARBALL}"
wget -q "http://ftp.openbsd.org/pub/OpenBSD/LibreSSL/${LIBRESSL_TARBALL}.asc"
echo -e "${COLOUR}Done.\e[0m"

echo -ne "${COLOUR}Verifying authenticity of ${LIBRESSL_TARBALL}...\e[0m"
export GNUPGHOME=${temp_dir}
gpg --keyserver ha.pool.sks-keyservers.net --recv-keys "${GPG_LIBRESSL}"
gpg --batch --verify "${LIBRESSL_TARBALL}.asc" "${LIBRESSL_TARBALL}"
unset GNUPGHOME
echo -e "${COLOUR}Done.\e[0m"

echo -ne "${COLOUR}Unpacking source...\e[0m"
tar -xzf "${LIBRESSL_TARBALL}"
echo -e "${COLOUR}Done.\e[0m"

cd ${temp_dir}
echo -ne "${COLOUR}Downloading source for libressl...\e[0m"
wget -q https://nginx.org/download/${NGINX_TARBALL}
wget -q https://nginx.org/download/${NGINX_TARBALL}.asc
echo -e "${COLOUR}Done.\e[0m"

echo -ne "${COLOUR}Verifying authenticity of ${NGINX_TARBALL}...\e[0m"
export GNUPGHOME=${temp_dir}
gpg --keyserver ha.pool.sks-keyservers.net --recv-keys "${GPG_NGINX}"
gpg --verify "${NGINX_TARBALL}.asc"
unset GNUPGHOME
echo -e "${COLOUR}Done.\e[0m"

echo -ne "${COLOUR}Unpacking source...\e[0m"
tar -xzf "${NGINX_TARBALL}"
echo -e "${COLOUR}Done.\e[0m"

echo -ne "${COLOUR}Configuring and making...\e[0m"
cd nginx-${NGINX_VERSION}
./configure \
  --prefix=/etc/nginx \
  --sbin-path=/usr/sbin/nginx \
  --with-cc-opt='-O3 -fPIE -fstack-protector-strong -Wformat -Werror=format-security' \
  --with-ld-opt='-Wl,-Bsymbolic-functions -Wl,-z,relro' \
  --with-openssl="${temp_dir}/libressl-${LIBRESSL_VERSION}" \
  --with-http_ssl_module \
  --with-http_v2_module \
  --with-http_gzip_static_module \
  --with-http_stub_status_module \
  --with-file-aio \
  --with-threads \
  --with-pcre-jit \
  --without-http_ssi_module \
  --without-http_scgi_module \
  --without-http_uwsgi_module \
  --without-http_geo_module \
  --without-http_autoindex_module \
  --without-http_map_module \
  --without-http_split_clients_module \
  --without-http_memcached_module \
  --without-http_empty_gif_module \
  --without-http_browser_module \
  --http-log-path=/var/log/nginx/access.log \
  --error-log-path=/var/log/nginx/error.log \
  --add-module="${temp_dir}/ngx_brotli" \

make -j${nproc}
make install
make clean

# forward request and error logs to docker log collector
# Redirect to STDOUT/STDERROR of PID 1, because PID 1 is the
# process launched by docker
ln -sf /proc/1/fd/1 /var/log/nginx/access.log
ln -sf /proc/1/fd/2 /var/log/nginx/error.log

# The latest version of nginx stores its pid in /run/nginx/
mkdir -p /run/nginx
echo -e "${COLOUR}Done.\e[0m"

# Clean up
echo -ne "${COLOUR}Cleaning up...\e[0m"
cd /
strip -s /usr/sbin/nginx
apk del ${BUILD_DEPS}
rm -rf /var/cache/apk/* ${temp_dir}
echo -e "${COLOUR}Done.\e[0m"
