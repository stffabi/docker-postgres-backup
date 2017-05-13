#!/bin/sh
set -e

if [ "${MYSQL_ENV_MYSQL_PASS}" == "**Random**" ]; then
        unset MYSQL_ENV_MYSQL_PASS
fi

MYSQL_HOST=${MYSQL_PORT_3306_TCP_ADDR:-${MYSQL_HOST}}
MYSQL_HOST=${MYSQL_PORT_1_3306_TCP_ADDR:-${MYSQL_HOST}}
MYSQL_PORT=${MYSQL_PORT_3306_TCP_PORT:-${MYSQL_PORT}}
MYSQL_PORT=${MYSQL_PORT_1_3306_TCP_PORT:-${MYSQL_PORT}}
MYSQL_USER=${MYSQL_USER:-${MYSQL_ENV_MYSQL_USER}}
MYSQL_PASS=${MYSQL_PASS:-${MYSQL_ENV_MYSQL_PASS}}

[ -z "${MYSQL_HOST}" ] && { echo "=> MYSQL_HOST cannot be empty" && exit 1; }
[ -z "${MYSQL_PORT}" ] && { echo "=> MYSQL_PORT cannot be empty" && exit 1; }
[ -z "${MYSQL_USER}" ] && { echo "=> MYSQL_USER cannot be empty" && exit 1; }
[ ! -z "${MYSQL_PASS}" ] && { MYSQL_PASS="-p${MYSQL_PASS}"; }

BACKUP_CMD="mysqldump -h${MYSQL_HOST} -P${MYSQL_PORT} -u${MYSQL_USER} ${MYSQL_PASS} ${EXTRA_OPTS} ${MYSQL_DB} | gzip > /backup/"'${BACKUP_NAME}'

echo "=> Creating backup script"
rm -f /backup.sh
cat <<EOF >> /backup.sh
#!/bin/sh
set -e

MAX_BACKUPS=${MAX_BACKUPS}

BACKUP_NAME=\$(date +\%Y.\%m.\%d.\%H\%M\%S).sql.gz

echo "=> Backup started: \${BACKUP_NAME}"
if ${BACKUP_CMD} ;then
    (cd /backup; rm -f latest.sql.gz; ln -s \${BACKUP_NAME} latest.sql.gz)
    echo "   Backup succeeded"
else
    echo "   Backup failed"
    rm -rf /backup/\${BACKUP_NAME}
fi

if [ -n "\${MAX_BACKUPS}" ]; then
    while [ \$(ls /backup/*.sql.gz -1 | wc -l) -gt \${MAX_BACKUPS} ];
    do
        BACKUP_TO_BE_DELETED=\$(ls /backup/*.sql.gz -1 | sort | head -n 1)
        echo "   Backup \${BACKUP_TO_BE_DELETED} is deleted"
        rm -rf \${BACKUP_TO_BE_DELETED}
    done
fi
echo "=> Backup done"
EOF
chmod +x /backup.sh

echo "=> Creating restore script"
rm -f /restore.sh
cat <<EOF >> /restore.sh
#!/bin/sh
set -e

echo "=> Restore database from \$1"
if cat \$1 | gzip -d | mysql -h${MYSQL_HOST} -P${MYSQL_PORT} -u${MYSQL_USER} ${MYSQL_PASS} ;then
    echo "   Restore succeeded"
else
    echo "   Restore failed"
fi
echo "=> Done"
EOF
chmod +x /restore.sh

touch /mysql_backup.log
chown $UID:$GID /mysql_backup.log
exec su-exec $UID:$GID tail -F /mysql_backup.log &

if [ -n "${INIT_BACKUP}" ]; then
    echo "=> Create a backup on startup"
    /backup.sh
elif [ -n "${INIT_RESTORE_LATEST}" ]; then
    echo "=> Restore latest backup"
    until nc -z $MYSQL_HOST $MYSQL_PORT
    do
        echo "waiting for database container..."
        sleep 1
    done
    ls -d -1 /backup/* | tail -1 | xargs /restore.sh
fi

if [ -n "${NO_CRON}" ]; then
    echo "NO_CRON set, exiting"
else
    echo "${CRON_TIME} /backup.sh >> /mysql_backup.log 2>&1" > /crontab.conf
    echo "=> Running cron job"
    exec su-exec $UID:$GID go-crond $UID:/crontab.conf
fi
