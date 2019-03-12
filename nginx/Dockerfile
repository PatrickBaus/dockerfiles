FROM alpine:3.8
LABEL maintainer="Patrick Baus <patrick.baus@physik.tu-darmstadt.de>"

ARG NGINX_VERSION=1.15.9
ARG LIBRESSL_VERSION=2.8.3
ARG GPG_LIBRESSL="A1EB 079B 8D3E B92B 4EBD  3139 663A F51B D5E4 D8D5"
ARG GPG_NGINX="B0F4 2533 73F8 F6F5 10D4  2178 520A 9993 A1C0 52F8"
ARG BUILD_CORES

# Upgrade installed packages
RUN apk --no-cache upgrade

#############
# Nginx     #
#############

# Install build dependencies
RUN apk --no-cache add --virtual=build-dependencies \
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
  openssl && \
  apk --no-cache add \
    pcre \
    zlib \
    libgcc \
    libstdc++ \
    bind-tools

# Create the nginx user
RUN addgroup -S nginx && \
 adduser -D -S -h /var/cache/nginx -s /sbin/nologin -G nginx nginx

# Install libbrotli
RUN NPROC=${BUILD_CORES-$(grep -c ^processor /proc/cpuinfo 2>/dev/null || 1)} && \
  TEMP_DIR="$(mktemp -d)" && \
  LIBRESSL_TARBALL="libressl-${LIBRESSL_VERSION}.tar.gz" && \
  NGINX_TARBALL="nginx-${NGINX_VERSION}.tar.gz" && \
  cd ${TEMP_DIR} && \
  git clone https://github.com/bagder/libbrotli --depth=1 && \
  cd libbrotli && \
  ./autogen.sh && \
  ./configure && \
  make -j${NPROC} && \
  make install && \
  cd ${TEMP_DIR} && \
  git clone https://github.com/google/ngx_brotli --depth=1 && \
  cd ngx_brotli && \
  git submodule update --init && \
  cd ${TEMP_DIR} && \
  wget -q "http://ftp.openbsd.org/pub/OpenBSD/LibreSSL/${LIBRESSL_TARBALL}" && \
  wget -q "http://ftp.openbsd.org/pub/OpenBSD/LibreSSL/${LIBRESSL_TARBALL}.asc" && \
  export GNUPGHOME=${TEMP_DIR} && \
  gpg --keyserver pgp.mit.edu --recv-keys "${GPG_LIBRESSL}" || \
  gpg --keyserver keyserver.pgp.com --recv-keys "${GPG_LIBRESSL}" || \
  gpg --keyserver ha.pool.sks-keyservers.net --recv-keys "${GPG_LIBRESSL}" && \
  gpg --batch --verify "${LIBRESSL_TARBALL}.asc" "${LIBRESSL_TARBALL}" && \
  unset GNUPGHOME && \
  tar -xzf "${LIBRESSL_TARBALL}" && \
  wget -q https://nginx.org/download/${NGINX_TARBALL} && \
  wget -q https://nginx.org/download/${NGINX_TARBALL}.asc && \
  gpg --keyserver pgp.mit.edu --recv-keys "${GPG_NGINX}" || \
  gpg --keyserver keyserver.pgp.com --recv-keys "${GPG_NGINX}" || \
  gpg --keyserver ha.pool.sks-keyservers.net --recv-keys "${GPG_NGINX}" && \
  gpg --verify "${NGINX_TARBALL}.asc" && \
  tar -xzf "${NGINX_TARBALL}" && \
  cd nginx-${NGINX_VERSION} && \
  ./configure \
  --prefix=/etc/nginx \
  --sbin-path=/usr/sbin/nginx \
  --user=nginx \
  --group=nginx \
  --with-cc-opt='-O3 -fPIE -fstack-protector-strong -Wformat -Werror=format-security -Wno-deprecated-declarations' \
  --with-ld-opt='-Wl,-Bsymbolic-functions -Wl,-z,relro' \
  --with-openssl="${TEMP_DIR}/libressl-${LIBRESSL_VERSION}" \
  --with-http_ssl_module \
  --with-http_sub_module \
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
  --add-module="${TEMP_DIR}/ngx_brotli" && \
  make -j${NPROC} && \
  make install && \
  rm -rf ${TEMP_DIR} && \
  ln -sf /proc/1/fd/1 /var/log/nginx/access.log && \
  ln -sf /proc/1/fd/2 /var/log/nginx/error.log && \
  mkdir -p /run/nginx && \
  strip -s /usr/sbin/nginx && \
  apk del build-dependencies

# Copy the default nginx config to the image
# Do not touch these files unless you know what you doing
COPY nginx_conf/nginx.conf /etc/nginx/conf/nginx.conf
COPY nginx_conf/vhost_https.conf /etc/nginx/sites-enabled/proxy.conf
COPY nginx_conf/ssl_params /etc/nginx/conf/ssl_params
COPY nginx_conf/headers_params /etc/nginx/conf/headers_params
COPY nginx_conf/proxy_params /etc/nginx/conf/proxy_params

# Copy certificates to the image
#COPY server.crt /etc/nginx/certs/
#COPY server.key /etc/nginx/certs/

#############
# Debug     #
#############
# Uncomment this to enable a terminal for nano
ENV TERM xterm
RUN apk --no-cache add nano

COPY entrypoint.sh /
RUN chmod +x /entrypoint.sh

EXPOSE 80 443

#VOLUME /sites-enabled /www /conf.d /passwds /certs /var/log/nginx

LABEL description="nginx built from source." \
      openssl="LibreSSL ${LIBRESSL_VERSION}." \
      nginx="nginx ${NGINX_VERSION}."

ENTRYPOINT ["/entrypoint.sh"]

CMD /usr/sbin/nginx
