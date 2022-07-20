FROM alpine:3.16

LABEL maintainer="Patrick Baus <patrick.baus@physik.tu-darmstadt.de>"

# Upgrade installed packages
RUN apk --no-cache upgrade

# Install openldap
RUN apk --no-cache add \
  openldap \
  openldap-clients \
  openldap-overlay-memberof \
  openldap-overlay-refint \
  openldap-overlay-ppolicy \
  openldap-back-mdb \
  su-exec

# Copy the default slapd config to the image
# Do not touch this file unless you know what you doing
# It will be modified by the startup script
COPY slapd.conf /etc/openldap/slapd.conf.default

COPY modules/ /etc/openldap/modules
COPY data/ /etc/openldap/data
COPY schema/ /etc/openldap/schema

#############
# Debug     #
#############
# Uncomment this to enable a terminal for nano
#ENV TERM xterm
#RUN apk -U add nano
#RUN rm -rf /var/cache/apk/*

COPY entrypoint.sh /
RUN chmod +x /entrypoint.sh

EXPOSE 389

ENTRYPOINT ["/entrypoint.sh"]

# Set the debug level
# Run "slapd -d ?" for a list of levels
# 32768 is None
CMD ["slapd", "-d", "32768", "-u", "ldap", "-g", "ldap"]
