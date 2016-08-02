FROM alpine

MAINTAINER Patrick Baus <patrick.baus@physik.tu-darmstadt.de>

# Uncomment this to enable a terminal for nano
# ENV TERM xterm

# Install openldap
RUN  apk update \
  && apk add openldap \
  # Uncomment this for debugging
  # If enabling nano, make sure the xterm enviroment variable is set as well (see above)
  # && apk add openldap-clients \
  # && apk add nano \
  && rm -rf /var/cache/apk/*

# Copy the default slapd config to the image
# Do not touch this file unless you know what you doing
# It will be modified by the startup script
COPY slapd.conf /etc/openldap/slapd.conf

COPY modules/ /etc/openldap/modules
COPY database/ /etc/openldap/database
COPY schema/ /etc/openldap/schema

COPY entrypoint.sh /
RUN chmod +x /entrypoint.sh

EXPOSE 389

ENTRYPOINT ["/entrypoint.sh"]

# Set the debug level
# Run "slapd -d ?" for a list of levels
# 32768 is None
CMD ["slapd", "-d", "32768", "-u", "ldap", "-g", "ldap"]
