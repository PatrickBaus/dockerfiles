FROM alpine:3.16
LABEL maintainer="Patrick Baus <patrick.baus@physik.tu-darmstadt.de>"

ARG NGINX_VERSION=1.23.0
ARG LIBRESSL_VERSION=3.5.3
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

COPY libressl_signing_key.txt nginx_signing_key.txt /

# Install libbrotli
RUN NPROC=${BUILD_CORES-$(grep -c ^processor /proc/cpuinfo 2>/dev/null || 1)} && \
  TEMP_DIR="$(mktemp -d)" && \
  LIBRESSL_TARBALL="libressl-${LIBRESSL_VERSION}.tar.gz" && \
  NGINX_TARBALL="nginx-${NGINX_VERSION}.tar.gz" && \
  cd ${TEMP_DIR} && \
  git clone https://github.com/google/ngx_brotli.git --depth=1 && \
  cd ngx_brotli && \
  git submodule update --init && \
  cd ${TEMP_DIR} && \
  wget -q "http://ftp.openbsd.org/pub/OpenBSD/LibreSSL/${LIBRESSL_TARBALL}" && \
  wget -q "http://ftp.openbsd.org/pub/OpenBSD/LibreSSL/${LIBRESSL_TARBALL}.asc" && \
  export GNUPGHOME=${TEMP_DIR} && \
  gpg --import /libressl_signing_key.txt && \
  gpg --batch --verify "${LIBRESSL_TARBALL}.asc" "${LIBRESSL_TARBALL}" && \
  tar -xzf "${LIBRESSL_TARBALL}" && \
  wget -q "https://nginx.org/download/${NGINX_TARBALL}" && \
  wget "https://nginx.org/download/${NGINX_TARBALL}.asc" && \
  gpg --import /nginx_signing_key.txt && \
  gpg --verify "${NGINX_TARBALL}.asc" && \
  unset GNUPGHOME && \
  tar -xzf "${NGINX_TARBALL}" && \
  cd nginx-${NGINX_VERSION} && \
  ./configure \
  --prefix=/etc/nginx \
  --sbin-path=/usr/sbin/nginx \
  --user=nginx \
  --group=nginx \
  --with-cc-opt='-O3 -fPIE -fstack-protector-strong -Wformat -Werror=format-security -Wno-deprecated-declarations -DTLS1_3_VERSION=0x0304' \
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
  --with-openssl-opt='enable-tls1_3' \
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

CMD while true; do sleep 6h; nginx -s reload; done & exec nginx
