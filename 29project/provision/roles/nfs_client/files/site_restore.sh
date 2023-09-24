#!/bin/sh

RESTORE_DATE=$1 #ddmmyyyy
BACKUP_DIR="/mnt/share/upload/site"
SITE_DIR="/usr/share/nginx/html/wordpress"

### Восстановление файлов в локальную папку  ###

if [[ -n "$1" ]]
then
tar -C $SITE_DIR -xvf $BACKUP_DIR/wordpress_$RESTORE_DATE.tar.gz

else
	echo "Please enter the date in the format ddmmyyyy. Exit..."
	exit
fi

### Проверка выгрузки ###
if test $? = 0
then
 echo "Files restored"
else
 echo "File recovery error"
fi
