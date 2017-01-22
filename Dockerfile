FROM alpine:3.5
MAINTAINER Johan Swetzén <johan@swetzen.com>

RUN apk add --no-cache mysql-client && \
    mkdir /backup

ENV CRON_TIME="0 0 * * *" \
    MYSQL_DB="--all-databases" \
    MYSQL_HOST="mariadb" \
    MYSQL_PORT="3306" \
    MYSQL_USER="root" \
    MYSQL_PASS="" \
    EXTRA_OPTS="-A -R -E --triggers --single-transaction --flush-privileges"

ADD run.sh /run.sh

VOLUME ["/backup"]

CMD ["/run.sh"]
