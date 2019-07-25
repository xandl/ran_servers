#!/bin/bash

COUNT=${1:-6}
WORK=${2:-/backup/database}
TARGET=$WORK/backup_$(date +"%Y-%m-%d_%H-%M-%S")

if [ ! -f /etc/cron.d/ran_backup ]; then
    echo "CREATE Crontab file..."
    echo "SHELL=/bin/bash" > /etc/cron.d/ran_backup
    echo "PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin" >> /etc/cron.d/ran_backup
    echo "MAILTO=root" >> /etc/cron.d/ran_backup
    echo "1 6,18 * * * root "$(realpath $0)  >> /etc/cron.d/ran_backup
    echo "" >> /etc/cron.d/ran_backup
fi
mkdir -p $WORK

cd $WORK
if [ $(ls -ld backup_* | wc -l) -gt $COUNT ]; then
    echo "DELETE old backup files..."
    rm -vrf $(ls -dr backup_*  | tail +$COUNT)
fi

echo "Create directory $TARGET"
mkdir -p $TARGET

mysql --version | grep "Distrib 5\.[56789]" > /dev/null 2>&1
if [ $? -eq 0 ]; then
        MYSQLEVENTS=1
else
        MYSQLEVENTS=0
fi


for DB in $(echo "show databases" | mysql -N | grep -v  information_schema ); do
        echo -n $(date +"%Y-%m-%d %H:%M:%S")": "
        echo -n dumping database $DB
        if [ $DB = "mysql" -a $MYSQLEVENTS -eq 1 ]; then
                EVENTS="--events"
        else
                EVENTS=""
        fi
        mysqldump --single-transaction --add-drop-table --disable-keys $EVENTS $DB 2>&1 > $TARGET/$DB.sql
        echo " done"
done
echo
