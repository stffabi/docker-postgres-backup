# mysql-backup

This image runs mysqldump to backup data using cronjob to folder `/backup`. Backups are named with date and time, the latest backup is linked to `/backup/latest.sql`.

Uses Alpine Linux for a small (36 MB) image.

## Usage:

    docker run -d \
        --env MYSQL_HOST=mariadb.host \
        --env MYSQL_PORT=3306 \
        --env MYSQL_USER=admin \
        --env MYSQL_PASS=password \
        --volume host.folder:/backup
        jswetzen/mysql-backup

Moreover, if you link `jswetzen/mysql-backup` to a mariadb container with an alias named mariadb, this image has defaults that will connect to `mariadb` on port 3306 with user `root` and no password.

    docker run -d -e MYSQL_ALLOW_EMPTY_PASSWORD=true --name mariadb mariadb
    docker run -d --link mariadb:mariadb -v host.folder:/backup jswetzen/mysql-backup

## Parameters

    MYSQL_HOST      the host/ip of your mysql database
    MYSQL_PORT      the port number of your mysql database
    MYSQL_USER      the username of your mysql database
    MYSQL_PASS      the password of your mysql database
    MYSQL_DB        the database name to dump. Default: `--all-databases`
    EXTRA_OPTS      the extra options to pass to mysqldump command
    CRON_TIME       the interval of cron job to run mysqldump. `0 0 * * *` by default, which is every day at 00:00
    MAX_BACKUPS     the number of backups to keep. When reaching the limit, the old backup will be discarded. No limit by default
    INIT_BACKUP     if set, create a backup when the container starts
    INIT_RESTORE_LATEST if set, restores latest backup
    NO_CRON         if set, do not start cron. Must be used with INIT_BACKUP to run a single backup and then exit

## Restore from a backup

See the list of backups, you can run:

    docker exec mysql-backup ls /backup

To restore database from a certain backup, simply run:

    docker exec mysql-backup /restore.sh /backup/2015.08.06.171901.sql

## Support

Add a [GitHub issue](https://github.com/jswetzen/mysql-backup/issues).
