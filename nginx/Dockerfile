FROM alpine
MAINTAINER Patrick Baus <patrick.baus@physik.tu-darmstadt.de>

ENV UID=991 GID=991

ARG NGINX_VERSION=1.11.3
ARG LIBRESSL_VERSION=2.4.2
ARG GPG_LIBRESSL="A1EB 079B 8D3E B92B 4EBD  3139 663A F51B D5E4 D8D5"
ARG GPG_NGINX="B0F4 2533 73F8 F6F5 10D4  2178 520A 9993 A1C0 52F8"
ARG BUILD_CORES

#############
# Nginx     #
#############
COPY install_nginx.sh /
RUN chmod +x /install_nginx.sh
RUN /install_nginx.sh

# Copy the default nginx config to the image
# Do not touch these files unless you know what you doing
COPY nginx_conf/nginx.conf /etc/nginx/conf/nginx.conf
COPY nginx_conf/vhost_https.conf /etc/nginx/sites-enabled/proxy.conf
COPY nginx_conf/ssl_params /etc/nginx/conf/ssl_params
COPY nginx_conf/headers_params /etc/nginx/conf/headers_params
COPY nginx_conf/proxy_params /etc/nginx/conf/proxy_params

# Copy helper scripts to the image
COPY ngxproxy /usr/local/bin/ngxproxy
RUN chmod +x /usr/local/bin/ngxproxy

#############
# Debug     #
#############
# Uncomment this to enable a terminal for nano
ENV TERM xterm
RUN apk -U add nano
RUN rm -rf /var/cache/apk/*

COPY entrypoint.sh /
RUN chmod +x /entrypoint.sh

EXPOSE 80 443

#VOLUME /sites-enabled /www /conf.d /passwds /certs /var/log/nginx

LABEL description="nginx built from source." \
      openssl="LibreSSL ${LIBRESSL_VERSION}." \
      nginx="nginx ${NGINX_VERSION}."

ENTRYPOINT ["/entrypoint.sh"]

CMD /usr/sbin/nginx
