#!/bin/sh

RESTORE_DATE=$1 #ddmmyyyy
BACKUP_DIR="/mnt/share/upload/dbase"
### Переменные доступа к СУБД ####
DB_USER="alex"
DB_PASSWORD="Otus#Linux2023"
DB_NAME="wordpress"

### Резервное копирование баз в локальную папку  ###

if [[ -n "$1" ]]
then
zcat $BACKUP_DIR/${DB_NAME}_${RESTORE_DATE}.sql.gz | mysql -u$DB_USER -p$DB_PASSWORD $DB_NAME

else
	echo "Please enter the date in the format ddmmyyyy. Exit..."
	exit
fi

### Проверка выгрузки ###
if test $? = 0
then
 echo "The database is restored"
else
 echo "Database restore error"
fi
