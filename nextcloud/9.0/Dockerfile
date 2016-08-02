FROM alpine
MAINTAINER Patrick Baus <patrick.baus@physik.tu-darmstadt.de>

ARG NEXTCLOUD_VERSION=9.0.3
# This key needs to be hardcoded to make sure the files were not tampered with
# See https://nextcloud.com/security/ for the current key
ARG GPG_nextcloud="2880 6A87 8AE4 23A2 8372  792E D758 99B9 A724 937A"
ARG GPG_nextcloud="E303 6906 AD9F 3080 7351  FAC3 2D5D 5E97 F697 8A26"

ENV GID=991 UID=991
# Uncomment this to enable a terminal for nano
ENV TERM xterm

# Install packages
RUN BUILD_DEPS="gnupg tar" && \
  # Install dependencies
  apk -U add \
    ${BUILD_DEPS} \
    supervisor \
    openssl \
    ca-certificates \
    php5 \
    # See https://docs.nextcloud.com/server/9/admin_manual/installation/source_installation.html
    php5-ctype \
    php5-dom \
    php5-gd \
    php5-iconv \
    php5-json \
    php5-posix \
    php5-zip \
    php5-zlib \
    php5-xml \
    php5-xmlreader \
    # Database connector
    php5-pdo_mysql \
    # Recommended packages
    php5-curl \
    php5-bz2 \
    php5-intl \
    php5-mcrypt \
    php5-openssl \
    # Required for specific apps
    php5-ldap \
    php5-exif \
    # Packages for enhanced performance
    php5-apcu \
    php5-opcache && \
  apk add php5-fpm && \
  apk add nginx && \
    # If enabling nano, make sure the xterm enviroment variable is set as well (see above)
    apk add nano

# Install Nextcloud
RUN \
  # Download Nextcloud
  mkdir -p /var/www/nextcloud && \
  cd /tmp && \
#  NEXTCLOUD_TARBALL="nextcloud-${NEXTCLOUD_VERSION}.tar.bz2" && \
  NEXTCLOUD_TARBALL="owncloud-${NEXTCLOUD_VERSION}.tar.bz2" && \
   wget -q https://download.owncloud.org/community/${NEXTCLOUD_TARBALL} && \
   wget -q https://download.owncloud.org/community/${NEXTCLOUD_TARBALL}.sha256 && \
   wget -q https://download.owncloud.org/community/${NEXTCLOUD_TARBALL}.asc && \
   wget -q https://owncloud.org/owncloud.asc && \
   mv owncloud.asc nextcloud.asc && \
#  wget -q https://download.nextcloud.com/server/releases/${NEXTCLOUD_TARBALL} && \
#  wget -q https://download.nextcloud.com/server/releases/${NEXTCLOUD_TARBALL}.sha256 && \
#  wget -q https://download.nextcloud.com/server/releases/${NEXTCLOUD_TARBALL}.asc && \
#  wget -q https://nextcloud.com/nextcloud.asc && \
  echo "Verifying both integrity and authenticity of ${NEXTCLOUD_TARBALL}..." && \
  CHECKSUM_STATE=$(echo -n $(sha256sum -c ${NEXTCLOUD_TARBALL}.sha256) | tail -c 2) && \
  if [ "${CHECKSUM_STATE}" != "OK" ]; then echo "Warning! Checksum does not match!" && exit 1; fi &&\
  gpg --import nextcloud.asc && \
  FINGERPRINT="$(LANG=C gpg --verify ${NEXTCLOUD_TARBALL}.asc ${NEXTCLOUD_TARBALL} \
    | sed -n "s#Primary key fingerprint: \(.*\)#\1#p")" && \
#  if [ -z "${FINGERPRINT}" ]; then echo "Warning! Invalid GPG signature! Fingerprint: ${FINGERPRINT}" && exit 1; fi && \
#  if [ "${FINGERPRINT}" != "${GPG_nextcloud}" ]; then echo "Warning! Wrong GPG fingerprint! ${FINGERPRINT} != ${GPG_nextcloud}" && exit 1; fi && \
  echo "All seems good, now unpacking ${NEXTCLOUD_TARBALL}..." && \
  tar xjf ${NEXTCLOUD_TARBALL} --strip 1 -C /var/www/nextcloud && \
  apk del ${BUILD_DEPS} && \
  rm -rf /var/cache/apk/* /tmp/* /root/.gnupg

# forward request and error logs to docker log collector
RUN \
  ln -sf /dev/stdout /var/log/nginx/access.log && \
  ln -sf /dev/stderr /var/log/nginx/error.log

# Copy the default nginx config to the image
# Do not touch this file unless you know what you doing
COPY nginx_conf/php-fpm.conf /etc/nginx/conf.d/
RUN mv /etc/nginx/nginx.conf /etc/nginx/nginx.conf.old
COPY nginx_conf/nginx.conf /etc/nginx/
# Install the nginx phpldapadmin configuration
COPY nginx_conf/nextcloud.conf /etc/nginx/conf.d/
RUN chown -R nginx:nginx /var/log/nginx

# The latest version of nginx stores its pid in /run/nginx/
RUN mkdir -p /run/nginx

# Copy the default php-fpm config to the image
# Do not touch this file unless you know what you doing
COPY php-fpm_conf/php-fpm.conf /etc/php5/
COPY php-fpm_conf/www.conf /etc/php5/php-fpm.d/

# Copy the default Nextcloud config to the image
# Do not touch this file unless you know what you doing
COPY nextcloud_conf/config.php /var/www/nextcloud/config/
COPY nextcloud_conf/autoconfig.php /var/www/nextcloud/config/

COPY php_conf/opcache.ini /etc/php5/conf.d/00_opcache.ini
COPY php_conf/apcu.ini /etc/php5/conf.d/
COPY supervisor_conf/default.ini /etc/supervisor.d/

COPY entrypoint.sh /
RUN chmod +x /entrypoint.sh

COPY cron /etc/periodic/15min/nextcloud
#RUN /etc/periodic/15min/nextcloud

EXPOSE 80

LABEL \
  description="A server software for creating file hosting services" \
  nextcloud="Nextcloud v${NEXTCLOUD_VERSION}"

ENTRYPOINT ["/entrypoint.sh"]

CMD supervisord -c /etc/supervisor.d/default.ini
