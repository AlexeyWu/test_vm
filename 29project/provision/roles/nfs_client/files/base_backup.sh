#!/bin/sh

### Локальные переменные  ####
DATE=`date +%d%m%Y`
BACKUP_DIR="/mnt/share/upload/dbase"
### Переменные доступа к СУБД ####
DB_USER="alex"
DB_PASSWORD="Otus#Linux2023"
DB_NAME="wordpress"

### Резервное копирование баз в локальную папку  ###

mysqldump -u$DB_USER -p$DB_PASSWORD $DB_NAME --set-gtid-purged=OFF | gzip > $BACKUP_DIR/${DB_NAME}_${DATE}.sql.gz

### Проверка выгрузки ###
if test $? = 0
then
 echo "Файлы выгружены на сервер"
else
 echo "Ошибка выгрузки на сервер"
fi
