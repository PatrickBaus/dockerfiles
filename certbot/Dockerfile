FROM certbot/certbot
LABEL maintainer="Patrick Baus <patrick.baus@physik.tu-darmstadt.de>"

# Upgrade installed packages
RUN apk --no-cache upgrade

#############
# Certbot   #
#############

#############
# Debug     #
#############
# Uncomment this to enable a terminal for nano
ENV TERM xterm
RUN apk --no-cache add nano

COPY cli.ini /etc/letsencrypt/
