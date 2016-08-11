FROM nginx:alpine

MAINTAINER Patrick Baus <patrick.baus@physik.tu-darmstadt.de>

# Install php and phpldapadmin
RUN apk -U add \
  php-fpm \
  phpldapadmin \
  supervisor
RUN rm -rf /var/cache/apk/*

# Copy the default nginx config to the image
# Do not touch this file unless you know what you doing
COPY nginx_conf/php-fpm.conf /etc/nginx/conf.d/
# Install the nginx phpldapadmin configuration
COPY nginx_conf/phpldapadmin.conf /etc/nginx/conf.d/
RUN rm /etc/nginx/conf.d/default.conf
# Make sure nginx stays in the foreground and does not daemonize
RUN echo "daemon off;" >> /etc/nginx/nginx.conf
RUN chown -R nginx:nginx /var/log/nginx

# Copy the default php-fpm config to the image
# Do not touch these files unless you know what you doing
COPY php-fpm_conf/php-fpm.conf /etc/php/
COPY php-fpm_conf/www.conf /etc/php/php-fpm.d/

# Copy the default phpldapadmin config to the image
# Do not touch this file unless you know what you doing
COPY phpldapadmin_conf/config.php /usr/share/webapps/phpldapadmin/config/

# Copy the default supervisord config to the image
# Do not touch this file unless you know what you doing
COPY supervisor_conf/default.ini /etc/supervisor.d/

# Now apply a set of patches to phpLDAPadmin, which fixes issues
# with the current master. For details see
# https://github.com/PatrickBaus/phpLDAPadmin
RUN mkdir -p /patches
COPY patches/* /patches/
RUN cd /usr/share/webapps/phpldapadmin \
  && patch -p0 < /patches/proxy_ssl.patch \
  && patch -p0 < /patches/request_smuggling.patch \
  && rm -rf /patches

#############
# Debug     #
#############
# Uncomment this to enable a terminal for nano
#ENV TERM xterm
#RUN apk -U add nano
#RUN rm -rf /var/cache/apk/*

COPY entrypoint.sh /
RUN chmod +x /entrypoint.sh

EXPOSE 80

ENTRYPOINT ["/entrypoint.sh"]

CMD supervisord -c /etc/supervisor.d/default.ini
