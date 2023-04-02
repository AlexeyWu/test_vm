# Systemd

## Напишем сервис, который будет раз в 30 секунд мониторить лог на предмет наличия ключевого слова. Файл и слово должны задаваться в /etc/sysconfig

- Для начала создаём файл с конфигурацией для сервиса в директории /etc/sysconfig - из неё сервис будет брать необходимые переменные

vi /etc/sysconfig/watchlog

```bash
# Configuration file for my watchlog service
# Place it to /etc/sysconfig
# File and word in that file that we will be monit
WORD="ALERT"
LOG=/var/log/watchlog.log
```

- Затем создаем /var/log/watchlog.log и пишем туда строки на своё усмотрение, плюс ключевое слово **ALERT**

- Создадим скрипт vi /opt/watchlog.sh

```bash
#!/bin/bash
WORD=$1
LOG=$2
DATE=`date`
if grep $WORD $LOG &> /dev/null
then
  logger "$DATE: I found word, Master!"
else
  exit 0
fi
```

> Команда logger отправляет лог в системный журнал
- Создадим юнит для сервиса watchlog - vi /etc/systemd/system/watchlog.service

```bash
[Unit]
Description=My watchlog service
[Service]
Type=oneshot
EnvironmentFile=/etc/sysconfig/watchlog
ExecStart=/opt/watchlog.sh $WORD $LOG
```

- Создадим юнит для таймера - vi /etc/systemd/system/watchlog.timer

```bash
[Unit]
Description=Run watchlog script every 30 second
[Timer]
# Run every 30 second
OnUnitActiveSec=30
Unit=watchlog.service
[Install]
WantedBy=multi-user.target
```

- Затем достаточно тольþко стартануть timer

```bash
systemctl start watchlog.timer
```

- И убедиться в результате

```bash
tail -f /var/log/messages
Apr  2 19:01:45 localhost systemd: Starting My watchlog service...
Apr  2 19:01:45 localhost root: Sun Apr  2 19:01:45 UTC 2023: I found word, Master!
Apr  2 19:01:45 localhost systemd: Started My watchlog service.
Apr  2 19:03:08 localhost systemd: Starting My watchlog service...
Apr  2 19:03:08 localhost root: Sun Apr  2 19:03:08 UTC 2023: I found word, Master!
Apr  2 19:03:08 localhost systemd: Started My watchlog service.
```

## Из epel установим spawn-fcgi и перепишем init-скрипт на unit-файл. Имя сервиса должно также называться

- Устанавливаем spawn-fcgi и необходимые для него пакеты

```bash
yum install epel-release -y && yum install spawn-fcgi php php-cli mod_fcgid httpd -y
```

> /etc/rc.d/init.d/spawn-fcg - cам Init скрипт, который будем переписывать  
> Но перед этим необходимо раскомментировать строки с переменными в /etc/sysconfig/spawn-fcgi
Он должен получится следующего вида:

```bash
# You must set some working options before the "spawn-fcgi" service will work.
# If SOCKET points to a file, then this file is cleaned up by the init script.
#
# See spawn-fcgi(1) for all possible options.
#
# Example :
SOCKET=/var/run/php-fcgi.sock
OPTIONS="-u apache -g apache -s $SOCKET -S -M 0600 -C 32 -F 1 -P /var/run/spawn-fcgi.pid -- /usr/bin/php-cgi"
```

- А сам юнит файл будет следующего вида - vi /etc/systemd/system/spawn-fcgi.service

```bash
[Unit]
Description=Spawn-fcgi startup service by Otus
After=network.target
[Service]
Type=simple
PIDFile=/var/run/spawn-fcgi.pid
EnvironmentFile=/etc/sysconfig/spawn-fcgi
ExecStart=/usr/bin/spawn-fcgi -n $OPTIONS
KillMode=process
[Install]
WantedBy=multi-user.target
```

- Убеждаемся что все успешно работает

```bash
systemctl start spawn-fcgi
systemctl status spawn-fcgi
● spawn-fcgi.service - Spawn-fcgi startup service by Otus
   Loaded: loaded (/etc/systemd/system/spawn-fcgi.service; disabled; vendor preset: disabled)
   Active: active (running) since Вс 2023-04-02 19:13:41 UTC; 6s ago
 Main PID: 25051 (php-cgi)
   CGroup: /system.slice/spawn-fcgi.service
           ├─25051 /usr/bin/php-cgi
           ├─25052 /usr/bin/php-cgi
           ├─25053 /usr/bin/php-cgi
           ├─25054 /usr/bin/php-cgi
           ├─25055 /usr/bin/php-cgi
           ├─25056 /usr/bin/php-cgi
           ├─25057 /usr/bin/php-cgi
           ├─25058 /usr/bin/php-cgi
           ├─25059 /usr/bin/php-cgi
           ├─25060 /usr/bin/php-cgi
           ├─25061 /usr/bin/php-cgi
           ├─25062 /usr/bin/php-cgi
           ├─25063 /usr/bin/php-cgi
           ├─25064 /usr/bin/php-cgi
           ├─25065 /usr/bin/php-cgi
           ├─25066 /usr/bin/php-cgi
           ├─25067 /usr/bin/php-cgi
           ├─25068 /usr/bin/php-cgi
           ├─25069 /usr/bin/php-cgi
           ├─25070 /usr/bin/php-cgi
           ├─25071 /usr/bin/php-cgi
           ├─25072 /usr/bin/php-cgi
           ├─25073 /usr/bin/php-cgi
           ├─25074 /usr/bin/php-cgi
           ├─25075 /usr/bin/php-cgi
           ├─25076 /usr/bin/php-cgi
           ├─25077 /usr/bin/php-cgi
           ├─25078 /usr/bin/php-cgi
           ├─25079 /usr/bin/php-cgi
           ├─25080 /usr/bin/php-cgi
           ├─25081 /usr/bin/php-cgi
           ├─25082 /usr/bin/php-cgi
           └─25083 /usr/bin/php-cgi

апр 02 19:13:41 localhost.localdomain systemd[1]: Started Spawn-fcgi startup service by Otus.
```

## Дополним юнит-файл apache httpd возможностью запустить несколько инстансов сервера с разными конфигами

- Для запуска нескольких экземпляров сервиса будем использовать шаблон в конфигурации файла окружения - vi /etc/systemd/system/httpd@second.service /etc/systemd/system/httpd@first.service

```bash
[Unit]
Description=The Apache HTTP Server
After=network.target remote-fs.target nss-lookup.target
Documentation=man:httpd(8)
Documentation=man:apachectl(8)
[Service]
Type=notify
EnvironmentFile=/etc/sysconfig/httpd-%I
ExecStart=/usr/sbin/httpd $OPTIONS -DFOREGROUND
ExecReload=/usr/sbin/httpd $OPTIONS -k graceful
ExecStop=/bin/kill -WINCH ${MAINPID}
KillSignal=SIGCONT
PrivateTmp=true
[Install]
WantedBy=multi-user.target
```

> Добавим параметр %I к EnvironmentFile=/etc/sysconfig/httpd
- В самом файле окружения (которых будет два) задается опция для запуска веб-сервера с необходимым конфигурационным файлом

/etc/sysconfig/httpd-first

```bash
OPTIONS=-f conf/first.conf
```

/etc/sysconfig/httpd-second

```bash
OPTIONS=-f conf/second.conf
```

- Соответственно в директории с конфигами httpd должны лежать два конфига, в нашем случае это будут first.conf и second.conf

```bash
cp /etc/httpd/conf/httpd.conf /etc/httpd/conf/first.conf                              
cp /etc/httpd/conf/httpd.conf /etc/httpd/conf/second.conf
```

> Для удачного запуска, в конфигурационных файлах должны быть указаны уникальные для каждого экземпляра опции **Listen** и **PidFile**.  
- Конфиги можно скопировать и поправить только второй, в нем должна быть следующие опции

```bash
PidFile /var/run/httpd-second.pid
Listen 8080
```

- Запустим

```bash
systemctl start httpd@first
systemctl start httpd@second
```

- Проверить можно несколькими способами, например посмотреть какие порты слушаются

```bash
ss -tnulp | grep httpd
tcp    LISTEN     0      128    [::]:8080               [::]:*                   users:(("httpd",pid=23502,fd=4),("httpd",pid=23501,fd=4),("httpd",pid=23500,fd=4),("httpd",pid=23499,fd=4),("httpd",pid=23498,fd=4),("httpd",pid=23497,fd=4),("httpd",pid=23496,fd=4))
tcp    LISTEN     0      128    [::]:80                 [::]:*                   users:(("httpd",pid=21992,fd=4),("httpd",pid=21991,fd=4),("httpd",pid=21990,fd=4),("httpd",pid=21989,fd=4),("httpd",pid=21988,fd=4),("httpd",pid=21987,fd=4),("httpd",pid=21986,fd=4))
```

