FROM alpine:3.5
MAINTAINER Fabrizio Steiner <stffabi@users.noreply.github.com>

RUN apk add --no-cache postgresql tzdata su-exec openssl && \
    mkdir /backup

RUN GOCROND_VERSION=0.3.0 \
    && wget -O /usr/local/bin/go-crond https://github.com/webdevops/go-crond/releases/download/$GOCROND_VERSION/go-crond-64-linux \
    && chmod +x /usr/local/bin/go-crond

ENV UID=65534 \
    GID=65534 \
    CRON_TIME="0 0 * * *" \
    PG_DB="postgres" \
    PG_HOST="postgres" \
    PG_PORT="5432" \
    PG_USER="root" \
    PG_PASS="" \
    EXTRA_OPTS="--inserts"

ADD run.sh /run.sh

VOLUME ["/backup"]

CMD ["/run.sh"]