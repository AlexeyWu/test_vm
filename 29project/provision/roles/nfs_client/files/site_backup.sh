#!/bin/sh

### локальные переменные  ####
DATE=`date +%d%m%Y`;
BACKUP_DIR="/mnt/share/upload/site"
### переменные доступа к папке ###
DIR="/usr/share/nginx/html/wordpress"
FILENAME="wordpress_$DATE"

### Резервное копирование сайтов в локальную папку ###
cd $DIR
tar -czf $BACKUP_DIR/$FILENAME.tar.gz ./

### Проверка выгрузки ###
if test $? = 0
then
 echo "Файлы выгружены на сервер"
else
 echo "Ошибка выгрузки на сервер"
fi
