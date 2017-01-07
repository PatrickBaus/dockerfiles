FROM alpine
MAINTAINER Patrick Baus <patrick.baus@physik.tu-darmstadt.de>

ARG NEXTCLOUD_VERSION=11.0.0
ARG LIBICONV_VERSION=1.14
# This key needs to be hardcoded to make sure the files were not tampered with
# See https://nextcloud.com/security/ for the current key
ENV GPG_NEXTCLOUD="2880 6A87 8AE4 23A2 8372  792E D758 99B9 A724 937A"

ENV GID=991 UID=991

# Install packages

#############
# Libiconv  #
#############
# Wating for https://bugs.alpinelinux.org/issues/5025 to be closed
# This install script will "monkey patch" the iconv library, so that
# libiconv will be called instead of the musl implemenatition.
COPY install_libiconv.sh /
RUN chmod +x /install_libiconv.sh
RUN /install_libiconv.sh
# "Monkey patch" the existing libiconv implementation
ENV LD_PRELOAD /usr/local/lib/preloadable_libiconv.so

#############
# PHP       #
#############
COPY install_php.sh /
RUN chmod +x /install_php.sh
RUN /install_php.sh

# Copy the default php and php-fpm config to the image
# Do not touch these files unless you know what you doing
COPY php-fpm_conf/php-fpm.conf /etc/php5/
COPY php-fpm_conf/www.conf /etc/php5/php-fpm.d/


#############
# Nextcloud #
#############
COPY install_nextcloud.sh /
COPY upgrade_nextcloud.sh /
RUN chmod +x /install_nextcloud.sh
RUN /install_nextcloud.sh

# Copy the default Nextcloud config to the image
# Do not touch these files unless you know what you doing
COPY nextcloud_conf/config.php /var/www/nextcloud/config/
COPY nextcloud_conf/autoconfig.php /var/www/nextcloud/config/

# Install the Nextcloud cron job, which replaces AJAX cron
COPY nextcloud_conf/cron /etc/periodic/15min/nextcloud
RUN chmod +x /etc/periodic/15min/nextcloud

#############
# Nginx     #
#############
COPY install_nginx.sh /
RUN chmod +x /install_nginx.sh
RUN /install_nginx.sh

# Copy the default nginx config to the image
# Do not touch these files unless you know what you doing
COPY nginx_conf/php-fpm.conf /etc/nginx/conf.d/
COPY nginx_conf/nginx.conf /etc/nginx/
# Install the nginx phpldapadmin configuration
COPY nginx_conf/nextcloud.conf /etc/nginx/conf.d/
RUN chown -R nginx:nginx /var/log/nginx

#############
# Supervisor#
#############
RUN apk -U add supervisor

# Copy the default supervisor config to the image
# Do not touch this file unless you know what you doing
COPY supervisor_conf/default.ini /etc/supervisor.d/
RUN rm -rf /var/cache/apk/*

#############
# Debug     #
#############
# Uncomment this to enable a terminal for nano
ENV TERM xterm
RUN apk -U add nano
RUN rm -rf /var/cache/apk/*

# Run the Nextcloud cron job once. We need to run this after nginx was installed, because
# it uses the nginx user account.
RUN /etc/periodic/15min/nextcloud

COPY entrypoint.sh /
RUN chmod +x /entrypoint.sh

EXPOSE 80

LABEL \
  description="A server software for creating file hosting services" \
  nextcloud="Nextcloud v${NEXTCLOUD_VERSION}"

ENTRYPOINT ["/entrypoint.sh"]

CMD supervisord -c /etc/supervisor.d/default.ini
