FROM alpine:3.8
LABEL maintainer="Patrick Baus <patrick.baus@physik.tu-darmstadt.de>"

COPY entrypoint.sh /
RUN chmod +x /entrypoint.sh

ENTRYPOINT /entrypoint.sh
