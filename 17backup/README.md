# 17. Резервное копирование 

### Задание

```
- Настроить стенд Vagrant с двумя виртуальными машинами: backup_server и client 
- Настроить удаленный бекап каталога /etc c сервера client при помощи borgbackup. Резервные копии должны соответствовать следующим критериям:
- Директория для резервных копий /var/backup. Это должна быть отдельная точка монтирования. В данном случае для демонстрации размер не принципиален, достаточно будет и 2GB.
- Репозиторий дле резервных копий должен быть зашифрован ключом или паролем - на ваше усмотрение
- Имя бекапа должно содержать информацию о времени снятия бекапа
- Глубина бекапа должна быть год, хранить можно по последней копии на конец месяца, кроме последних трех. 
- Последние три месяца должны содержать копии на каждый день. Т.е. должна быть правильно настроена политика удаления старых бэкапов
- Резервная копия снимается каждые 5 минут. Такой частый запуск в целях демонстрации.
- Написан скрипт для снятия резервных копий. Скрипт запускается из соответствующей Cron джобы, либо systemd timer-а - на ваше усмотрение.
- Настроено логирование процесса бекапа. Для упрощения можно весь вывод перенаправлять в logger с соответствующим тегом. Если настроите не в syslog, то обязательна ротация логов

Запустите стенд на 30 минут. Убедитесь что резервные копии снимаются. Остановите бекап, удалите (или переместите) директорию /etc и восстановите ее из бекапа. Для сдачи домашнего задания ожидаем настроенные стенд, логи процесса бэкапа и описание процесса восстановления.
```

- при запуске сервера создается второй диск емкостью 2Гб, который монтируется в /var/backup
```
[vagrant@server ~]$ lsblk
NAME   MAJ:MIN RM SIZE RO TYPE MOUNTPOINT
sda      8:0    0  40G  0 disk 
└─sda1   8:1    0  40G  0 part /
sdb      8:16   0   2G  0 disk 
└─sdb1   8:17   0   2G  0 part /etc/backup

```
- автоматическая инициализация репозитория в /var/backup
Borg prune хранит:
- все резервные копии за последние сутки (для проверки)
- по 1 резервной копии за последние 90 суток (3 месяца)
- по 1 резервной копии за последние 12 месяцев
- на клиенте для резервного копирования создается скрипт /usr/local/bin/borg_backup_script, который использует файл конфигурации /etc/borg_client/client_repo.conf. Логи складываются в файл /var/log/borg_client.log
- каждые 5 мин запускается скрипт резервного копирования. Проверить можно командой
```
sudo crontab -u root -l
```
### Проверка восстановления
- ждем 30 минут и проверяем
``` 
sudo BORG_PASSPHRASE=Otus1234 borg list borg@server:client_repo
```
получаем:
```
2023-06-22_21:30:02                  Thu, 2023-06-22 21:30:03 [d4a0dcba86d61aff44834a46eed15a85b7b366905fe9b49e0e047811e8a0a444]
2023-06-22_21:35:01                  Thu, 2023-06-22 21:35:02 [ec33f9ed5034b06f3123a3335f550a6eac2f7ff26082fc7dd6fddfeb7e2c4c8d]
2023-06-22_21:40:01                  Thu, 2023-06-22 21:40:03 [f871dd9faf7ad111a5d23f11a8c76d760b24bce2d59cbbef9f4b94d9e39cf94a]
2023-06-22_21:45:02                  Thu, 2023-06-22 21:45:03 [0412f14efa9179654563bc8fbb5ff51141c305c42701bbb43696c68013da4767]
2023-06-22_21:50:02                  Thu, 2023-06-22 21:50:03 [0d656a885bab243d75b928976abd54fa674025806059dd81aef0ae73c301ed40]

```
- останавливаем backup (переименовываем скрипт)
```
sudo mv /usr/local/bin/borg_backup_script /usr/local/bin/borg_backup_script_stopped
```
- поскольку удаление etc удалит и файл passwd, это приведет к невозможности подключиться удаленно к сервер. Поэтому сначала восстановим последний архив в домашнюю директорию пользователя root на клиенте.

```
su - root
```
Создаем папку ETC в директории ROOT
```
mkdir etc
```
- восстанавливаем архив с сервера в локальную папку /root/etc
```
sudo BORG_PASSPHRASE=Otus1234 borg extract borg@server:client_repo::2023-06-22_21:50:02 etc/

ls -la etc/
```
смотрим:
```
total 1076
drwxr-xr-x. 80 root root     8192 июн 22 21:29 .
dr-xr-x---.  8 root root      236 июн 22 21:53 ..
-rw-r--r--.  1 root root       16 апр 30  2020 adjtime
-rw-r--r--.  1 root root     1529 апр  1  2020 aliases
-rw-r--r--.  1 root root    12288 июн 22 20:56 aliases.db
drwxr-xr-x.  2 root root     4096 июн 22 20:59 alternatives
-rw-------.  1 root root      541 авг  8  2019 anacrontab
drwxr-x---.  3 root root       43 апр 30  2020 audisp
drwxr-x---.  3 root root       83 июн 22 20:56 audit
drwxr-xr-x.  2 root root       68 апр 30  2020 bash_completion.d
-rw-r--r--.  1 root root     2853 апр  1  2020 bashrc
drwxr-xr-x.  2 root root        6 апр  7  2020 binfmt.d
drwxr-xr-x.  2 root root       30 июн 22 21:29 borg_client
-rw-r--r--.  1 root root       37 ноя 23  2020 centos-release
-rw-r--r--.  1 root root       51 ноя 23  2020 centos-release-upstream
drwxr-xr-x.  2 root root        6 авг  4  2017 chkconfig.d
-rw-r--r--.  1 root root     1108 авг  8  2019 chrony.conf
-rw-r-----.  1 root chrony    481 авг  8  2019 chrony.keys
drwxr-xr-x.  2 root root       26 апр 30  2020 cifs-utils
drwxr-xr-x.  2 root root       21 апр 30  2020 cron.d
drwxr-xr-x.  2 root root       42 апр 30  2020 cron.daily
-rw-------.  1 root root        0 авг  8  2019 cron.deny
drwxr-xr-x.  2 root root       22 июн  9  2014 cron.hourly
drwxr-xr-x.  2 root root        6 июн  9  2014 cron.monthly
-rw-r--r--.  1 root root      451 июн  9  2014 crontab
drwxr-xr-x.  2 root root        6 июн  9  2014 cron.weekly
-rw-------.  1 root root        0 апр 30  2020 crypttab
-rw-r--r--.  1 root root     1620 апр  1  2020 csh.cshrc
-rw-r--r--.  1 root root     1103 апр  1  2020 csh.login
drwxr-xr-x.  4 root root       78 апр 30  2020 dbus-1
drwxr-xr-x.  2 root root       44 июн 22 20:59 default
drwxr-xr-x.  2 root root       54 июн 22 21:00 depmod.d
drwxr-x---.  4 root root       53 апр 30  2020 dhcp
-rw-r--r--.  1 root root     5090 авг  6  2019 DIR_COLORS
-rw-r--r--.  1 root root     5725 авг  6  2019 DIR_COLORS.256color
-rw-r--r--.  1 root root     4669 авг  6  2019 DIR_COLORS.lightbgcolor
-rw-r--r--.  1 root root     1285 апр  1  2020 dracut.conf
drwxr-xr-x.  2 root root       88 апр 30  2020 dracut.conf.d
-rw-r--r--.  1 root root      112 ноя 27  2019 e2fsck.conf
-rw-r--r--.  1 root root        0 апр  1  2020 environment
-rw-r--r--.  1 root root     1317 апр 11  2018 ethertypes
-rw-r--r--.  1 root root        0 июн  7  2013 exports
drwxr-xr-x.  2 root root        6 апр  1  2020 exports.d
-rw-r--r--.  1 root root       70 апр  1  2020 filesystems
...
```
- удаляем папку /etc
```
rm -rf /etc
```
rm: cannot remove ‘/etc’: Device or resource busy
```
ls -la /etc
```

```
total 0
drwxr-xr-x.  2 0 0   6 июн 22 21:54 .
dr-xr-xr-x. 18 0 0 255 июн 22 21:01 ..

```
- переносим восстановленную папку из /root/etc в /etc
```
cp -r etc /
```
- проверяем
```
ls -la /etc
```
```
total 1076
drwxr-xr-x. 80 root root   8192 июн 22 21:54 .
dr-xr-xr-x. 18 root root    255 июн 22 21:01 ..
-rw-r--r--.  1 root root     16 июн 22 21:54 adjtime
-rw-r--r--.  1 root root   1529 июн 22 21:54 aliases
-rw-r--r--.  1 root root  12288 июн 22 21:54 aliases.db
drwxr-xr-x.  2 root root   4096 июн 22 21:54 alternatives
-rw-------.  1 root root    541 июн 22 21:54 anacrontab
drwxr-x---.  3 root root     43 июн 22 21:54 audisp
drwxr-x---.  3 root root     83 июн 22 21:54 audit
drwxr-xr-x.  2 root root     68 июн 22 21:54 bash_completion.d
-rw-r--r--.  1 root root   2853 июн 22 21:54 bashrc
drwxr-xr-x.  2 root root      6 июн 22 21:54 binfmt.d
drwxr-xr-x.  2 root root     30 июн 22 21:54 borg_client
-rw-r--r--.  1 root root     37 июн 22 21:54 centos-release
-rw-r--r--.  1 root root     51 июн 22 21:54 centos-release-upstream
drwxr-xr-x.  2 root root      6 июн 22 21:54 chkconfig.d
-rw-r--r--.  1 root root   1108 июн 22 21:54 chrony.conf
-rw-r-----.  1 root root    481 июн 22 21:54 chrony.keys
drwxr-xr-x.  2 root root     26 июн 22 21:54 cifs-utils
drwxr-xr-x.  2 root root     21 июн 22 21:54 cron.d
drwxr-xr-x.  2 root root     42 июн 22 21:54 cron.daily
-rw-------.  1 root root      0 июн 22 21:54 cron.deny
drwxr-xr-x.  2 root root     22 июн 22 21:54 cron.hourly
drwxr-xr-x.  2 root root      6 июн 22 21:54 cron.monthly
-rw-r--r--.  1 root root    451 июн 22 21:54 crontab
drwxr-xr-x.  2 root root      6 июн 22 21:54 cron.weekly
-rw-------.  1 root root      0 июн 22 21:54 crypttab
-rw-r--r--.  1 root root   1620 июн 22 21:54 csh.cshrc
-rw-r--r--.  1 root root   1103 июн 22 21:54 csh.login
drwxr-xr-x.  4 root root     78 июн 22 21:54 dbus-1
drwxr-xr-x.  2 root root     44 июн 22 21:54 default
drwxr-xr-x.  2 root root     54 июн 22 21:54 depmod.d
drwxr-x---.  4 root root     53 июн 22 21:54 dhcp
-rw-r--r--.  1 root root   5090 июн 22 21:54 DIR_COLORS
-rw-r--r--.  1 root root   5725 июн 22 21:54 DIR_COLORS.256color
-rw-r--r--.  1 root root   4669 июн 22 21:54 DIR_COLORS.lightbgcolor
-rw-r--r--.  1 root root   1285 июн 22 21:54 dracut.conf
drwxr-xr-x.  2 root root     88 июн 22 21:54 dracut.conf.d
-rw-r--r--.  1 root root    112 июн 22 21:54 e2fsck.conf
-rw-r--r--.  1 root root      0 июн 22 21:54 environment
-rw-r--r--.  1 root root   1317 июн 22 21:54 ethertypes
-rw-r--r--.  1 root root      0 июн 22 21:54 exports
drwxr-xr-x.  2 root root      6 июн 22 21:54 exports.d
-rw-r--r--.  1 root root     70 июн 22 21:54 filesystems
drwxr-x---.  7 root root    133 июн 22 21:54 firewalld
-rw-r--r--.  1 root root    450 июн 22 21:54 fstab
-rw-r--r--.  1 root root     38 июн 22 21:54 fuse.conf
drwxr-xr-x.  2 root root      6 июн 22 21:54 gcrypt
drwxr-xr-x.  2 root root      6 июн 22 21:54 gnupg
-rw-r--r--.  1 root root     94 июн 22 21:54 GREP_COLORS
drwxr-xr-x.  4 root root     40 июн 22 21:54 groff
-rw-r--r--.  1 root root    557 июн 22 21:54 group
-rw-r--r--.  1 root root    543 июн 22 21:54 group-
lrwxrwxrwx.  1 root root     22 июн 22 21:54 grub2.cfg -> ../boot/grub2/grub.cfg
drwx------.  2 root root    182 июн 22 21:54 grub.d
...
```
- данные восстановлены
