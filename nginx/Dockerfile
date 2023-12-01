ARG NGINX_VERSION=1.25.3
ARG LIBRESSL_VERSION=3.8.2
ARG BUILD_CORES

FROM alpine:3.18.5 as builder

ARG NGINX_VERSION
ARG LIBRESSL_VERSION
ARG BUILD_CORES

# Upgrade installed packages and install base deps
RUN apk --no-cache upgrade \
  && apk --no-cache add --virtual=base-dependencies \
    build-base \
    cmake \
    ca-certificates \
    git \
    gnupg

COPY libressl_signing_key.txt nginx_signing_key.txt /

# Install libreSSL
RUN \
  set -ex \
  && NPROC=${BUILD_CORES-$(grep -c ^processor /proc/cpuinfo 2>/dev/null || 1)} \
  && LIBRESSL_TARBALL="libressl-${LIBRESSL_VERSION}.tar.gz" \
  && TEMP_DIR="$(mktemp -d)" \
  && cd ${TEMP_DIR} \
  && wget -q "http://ftp.openbsd.org/pub/OpenBSD/LibreSSL/${LIBRESSL_TARBALL}" \
  && wget -q "http://ftp.openbsd.org/pub/OpenBSD/LibreSSL/${LIBRESSL_TARBALL}.asc" \
  && export GNUPGHOME=${TEMP_DIR} \
  && gpg --import /libressl_signing_key.txt \
  && gpg --batch --verify "${LIBRESSL_TARBALL}.asc" "${LIBRESSL_TARBALL}" \
  && tar -xzf "${LIBRESSL_TARBALL}" \
  && unset GNUPGHOME \
  && cd libressl-${LIBRESSL_VERSION} \
  && ./configure \
    --prefix=/opt/libressl \
    --disable-tests \
    --enable-shared=yes \
    --enable-static=no \
  && make -j${NPROC} install_sw \
  && find /opt/libressl/lib -name '*.so.*' -exec cp -P {} /usr/lib \;

# Install libbrotli
RUN \
  set -ex \
  && NPROC=${BUILD_CORES-$(grep -c ^processor /proc/cpuinfo 2>/dev/null || 1)} \
  && mkdir -p /usr/src/ \
  && cd /usr/src/ \
  && git clone --recurse-submodules -j${NPROC} https://github.com/google/ngx_brotli.git \
  && cd ngx_brotli/deps/brotli \
  && mkdir out && cd out \
  && cmake -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=OFF -DCMAKE_C_FLAGS="-Ofast -m64 -march=native -mtune=native -flto=auto -funroll-loops -ffunction-sections -fdata-sections -Wl,--gc-sections" -DCMAKE_CXX_FLAGS="-Ofast -m64 -march=native -mtune=native -flto=auto -funroll-loops -ffunction-sections -fdata-sections -Wl,--gc-sections" -DCMAKE_INSTALL_PREFIX=./installed .. \
  && cmake --build . --config Release --target brotlienc

RUN \
  set -ex \
  && apk --no-cache add --virtual=nginx-dev-dependencies \
    linux-headers \
    pcre-dev \
    zlib-dev \
  && NPROC=${BUILD_CORES-$(grep -c ^processor /proc/cpuinfo 2>/dev/null || 1)} \
  && NGINX_TARBALL="nginx-${NGINX_VERSION}.tar.gz" \
  && TEMP_DIR="$(mktemp -d)" \
  && cd ${TEMP_DIR} \
  && wget -q "https://nginx.org/download/${NGINX_TARBALL}" \
  && wget "https://nginx.org/download/${NGINX_TARBALL}.asc" \
  && export GNUPGHOME=${TEMP_DIR} \
  && gpg --import /nginx_signing_key.txt \
  && gpg --verify "${NGINX_TARBALL}.asc" \
  && unset GNUPGHOME \
  && tar -xzf "${NGINX_TARBALL}" \
  && cd nginx-${NGINX_VERSION} \
  && ./configure \
    --prefix=/etc/nginx \
    --sbin-path=/usr/sbin/nginx \
    --user=nginx \
    --group=nginx \
    --with-cc-opt='-m64 -march=native -mtune=native -Ofast -flto=auto -funroll-loops -ffunction-sections -fdata-sections -Wl,--gc-sections' \
    --with-ld-opt='-m64 -Wl,-s -Wl,-Bsymbolic -Wl,--gc-sections' \
    --with-cc-opt="-I/opt/libressl/include" \
    --with-ld-opt="-L/opt/libressl/lib" \
    --with-http_ssl_module \
    --with-http_sub_module \
    --with-http_v2_module \
    --with-http_v3_module \
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
    --without-http_split_clients_module \
    --without-http_memcached_module \
    --without-http_empty_gif_module \
    --without-http_browser_module \
    --http-log-path=/var/log/nginx/access.log \
    --error-log-path=/var/log/nginx/error.log \
    --add-module="/usr/src/ngx_brotli" \
  && make -j${NPROC} \
  && make install

FROM alpine:3.18.5
LABEL maintainer="Patrick Baus <patrick.baus@physik.tu-darmstadt.de>"

ARG NGINX_VERSION
ARG LIBRESSL_VERSION
ARG BUILD_CORES

COPY --from=builder /usr/sbin/nginx /usr/sbin/nginx
COPY --from=builder /etc/nginx /etc/nginx
# Copy libreSSL
COPY --from=builder /usr/lib/libcrypto.so* /usr/lib/
COPY --from=builder /usr/lib/libssl.so* /usr/lib/
# Copy the default nginx config to the image
# Do not touch these files unless you know what you doing
COPY nginx_conf/nginx.conf /etc/nginx/conf/nginx.conf
COPY nginx_conf/vhost_https.conf /etc/nginx/sites-enabled/proxy.conf
COPY nginx_conf/ssl_params /etc/nginx/conf/ssl_params
COPY nginx_conf/headers_params /etc/nginx/conf/headers_params
COPY nginx_conf/proxy_params /etc/nginx/conf/proxy_params

RUN \
  set -ex \
  && addgroup -S nginx \
  && adduser -D -S -h /var/cache/nginx -s /sbin/nologin -G nginx nginx \
  && apk --no-cache add --virtual=nginx-dependencies \
    pcre \
    zlib \
  && mkdir /var/log/nginx \
  && touch /var/log/nginx/access.log /var/log/nginx/error.log \
  && ln -sf /dev/stdout /var/log/nginx/access.log \
  && ln -sf /dev/stderr /var/log/nginx/error.log

EXPOSE 80 443

LABEL description="nginx built from source." \
      openssl="LibreSSL ${LIBRESSL_VERSION}." \
      nginx="nginx ${NGINX_VERSION}."

CMD while true; do sleep 6h; nginx -s reload; done & exec nginx
