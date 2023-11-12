FROM alpine:3.18 as nextcloud-builder
ARG NEXTCLOUD_VERSION=27.1.3
# This key needs to be hardcoded to make sure the files were not tampered with
# See https://nextcloud.com/security/ for the current key
ARG GPG_NEXTCLOUD="2880 6A87 8AE4 23A2 8372  792E D758 99B9 A724 937A"

COPY nextcloud_signing_key.asc /

RUN \
  apk --no-cache add \
  gnupg \
  tar

RUN \
  temp_dir="$(mktemp -d)" && \
  cd ${temp_dir} && \
  NEXTCLOUD_TARBALL="nextcloud-${NEXTCLOUD_VERSION}.tar.bz2" && \
  echo -ne "Downloading source...\e[0m" && \
  wget -q https://download.nextcloud.com/server/releases/${NEXTCLOUD_TARBALL} && \
  wget -q https://download.nextcloud.com/server/releases/${NEXTCLOUD_TARBALL}.sha256 && \
  wget -q https://download.nextcloud.com/server/releases/${NEXTCLOUD_TARBALL}.asc && \
  if [ $(echo -n $(sha256sum -c "${NEXTCLOUD_TARBALL}.sha256") | tail -c 2) != "OK" ]; then echo -e "Error! Tarball checksum does not match!" && exit 1; fi && \
  gpg --import /nextcloud_signing_key.asc && \
  gpg --batch --verify "${NEXTCLOUD_TARBALL}.asc" "${NEXTCLOUD_TARBALL}" && \
  echo -ne "Unpacking source...\e[0m" && \
  mkdir /app && \
  tar xjf "${NEXTCLOUD_TARBALL}" --strip 1 -C /app

FROM alpine:3.18
LABEL maintainer="Patrick Baus <patrick.baus@physik.tu-darmstadt.de>"

# Default GID=101, UID=100
ENV GID=101 UID=100

# Upgrade installed packages
RUN apk --no-cache upgrade

# Install packages
#############
# PHP       #
#############
RUN apk --no-cache add gnu-libiconv \
  php81 \
  php81-bcmath \
  php81-ctype \
  php81-curl \
  php81-dom \
  php81-fileinfo \
  php81-gd \
  php81-gmp \
  php81-iconv \
  php81-intl \
  php81-json \
  php81-mbstring \
  php81-opcache \
  php81-openssl \
  php81-pcntl \
  php81-posix \
  php81-session \
  php81-simplexml \
  php81-sysvsem \
  php81-xml \
  php81-xmlreader \
  php81-xmlwriter \
  php81-zip \
  php81-zlib \
  php81-pdo_mysql \
  php81-bz2 \
#  php81-pecl-mcrypt \
  openssl \
  ca-certificates \
  php81-ldap \
  php81-exif \
  php81-apcu \
  php81-fpm \
  php81-pecl-imagick

# Copy the default php and php-fpm config to the image
# Do not touch these files unless you know what you doing
COPY php-fpm_conf/php-fpm.conf /etc/php81/
COPY php-fpm_conf/www.conf /etc/php81/php-fpm.d/
COPY php_conf/ /etc/php81/conf.d/

#############
# Nginx     #
#############
COPY install_nginx.sh /
RUN chmod +x /install_nginx.sh
RUN /install_nginx.sh

# Copy the default nginx config to the image
# Do not touch these files unless you know what you doing
COPY nginx_conf/php-fpm.conf /etc/nginx/http.d/
COPY nginx_conf/nginx.conf /etc/nginx/
# Install the nginx configuration
COPY nginx_conf/nextcloud.conf /etc/nginx/http.d/
RUN chown -R nginx:nginx /var/log/nginx
RUN rm /etc/nginx/http.d/default.conf

#############
# Nextcloud #
#############
COPY --from=nextcloud-builder /app /var/www/nextcloud/
COPY upgrade_nextcloud.sh /
RUN chmod +x /upgrade_nextcloud.sh

# Copy the default Nextcloud config to the image
# Do not touch these files unless you know what you doing
COPY nextcloud_conf/config.php /var/www/nextcloud/config/
COPY nextcloud_conf/autoconfig.php /var/www/nextcloud/config/

# Install the Nextcloud cron job, which replaces AJAX cron
COPY nextcloud_conf/cron /etc/periodic/15min/nextcloud
RUN chmod +x /etc/periodic/15min/nextcloud

# Run the Nextcloud cron job once. We need to run this after nginx was installed, because
# it uses the nginx user account.
RUN /etc/periodic/15min/nextcloud

#############
# Supervisor#
#############
RUN apk --no-cache add supervisor

# Copy the default supervisor config to the image
# Do not touch this file unless you know what you doing
COPY supervisor_conf/default.ini /etc/supervisor.d/

COPY entrypoint.sh /
RUN chmod +x /entrypoint.sh

EXPOSE 80

LABEL \
  description="A server software for creating file hosting services" \
  nextcloud="Nextcloud v${NEXTCLOUD_VERSION}"

ENTRYPOINT ["/entrypoint.sh"]

CMD supervisord -c /etc/supervisor.d/default.ini
