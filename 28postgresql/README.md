# Vagrant-стенд c Postgres

# Цель домашнего задания
Научиться настраивать репликацию и создавать резервные копии в СУБД PostgreSQL

# Описание домашнего задания
1) Настроить hot_standby репликацию с использованием слотов
2) Настроить правильное резервное копирование
# Введение
PostgreSQL — свободная объектно-реляционная система управления базами данных (СУБД). 
# Основные термины в Postgres:
Кластер - объединение нескольких баз данных. В postgres это означает что на одном хосте создаётся несколько баз сразу. 
База данных - физическое объединение объектов
Схема - логическое объединение таблиц в базе данных. По умолчанию в postgres создаётся одна схема под названием Public
# По умолчанию в кластере находятся:
- template0 - read only БД, содержащая инициализационный набор данных
- template1 - база-шаблон для создания новых баз
- postgres (при желании можно поменять название). В базе находятся служебные таблицы, можно также использовать данную базу для своих нужд, но это не рекомендуется.

Управлять базами, таблицами и данными можно не только с помощью консольной утилиты psql, но и с помощью GUI-утилит, например pgAdmin, Dbeaver  и т. д.

Postgres - это мультироцессное приложение. Состоит из главного процесса (postgres), который отвечает за подключение клиентов, взаимодействие с кэшом и отвечает за остальные процессы (background processes).

# Основные конфигурационные файлы в Postgres: 
pg_hba.conf -  файл задаёт способ доступа к базам и репликации из различных источников.
postgresql.conf - файл конфигурации, обычно находится в каталоге данных, может редактироваться вручную. Может быть несколько значений одного и того же параметра, тогда вступает в силу последнее значение.
postgresql.auto.conf - предназначен для автоматического изменения параметров postgres

# WAL (Write Ahead Log) - журнал упреждающей записи
В WAL записывается информация, достаточная для повторного выполнения всех действий с БД.
Записи этого журнала обязаны попасть на диск раньше, чем изменения в соответствующей странице. Журнал состоит из нескольких файлов (обычно по 16МБ), которые циклически перезаписываются.

Репликация - процесс синхронизации нескольких копий одного объекта. Решает задачу отказоустойчивости и масштабируемости.

# Задачи репликации:
балансировка нагрузки
резервирование (НЕ БЭКАП, бэкап можно делать с реплики)
обновление без остановки системы
горизонтальное масштабирование
геораспределение нагрузки

# Виды репликации:
Физическая репликация - описание изменений на уровне файлов. Побайтовая копия данных.
Логическая репликация - изменения данных в терминах строк таблиц. Более высокий уровень, чем файлы

Помимо репликации, рекомендуется создавать резервные копии. Они могут потребоваться, если вдруг сервера СУБД выйдут из строя. 


Запускаем наш Vagrantfile
``` 
vagrantfile up --no-provision
```
После установки нод запускаем настройку репликации и бекапировани с помощью ansible

```
vagrantfile up --provision
```


проверяем как синхронизируется со slave наша db


# NODE1
Создаем базу данных 

```
postgres=# CREATE DATABASE otus_test;
CREATE DATABASE
postgres=# postgres=# \l
                                  List of databases
   Name    |  Owner   | Encoding |   Collate   |    Ctype    |   Access privileges   
-----------+----------+----------+-------------+-------------+-----------------------
 otus_test | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 | 
 postgres  | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 | 
 template0 | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 | =c/postgres          +
           |          |          |             |             | postgres=CTc/postgres
 template1 | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 | =c/postgres          +
           |          |          |             |             | postgres=CTc/postgres
(4 rows)
```


# NODE2
проверяем репликацию

```
postgres=# postgres=# \l
                                  List of databases
   Name    |  Owner   | Encoding |   Collate   |    Ctype    |   Access privileges   
-----------+----------+----------+-------------+-------------+-----------------------
 otus_test | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 | 
 postgres  | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 | 
 template0 | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 | =c/postgres          +
           |          |          |             |             | postgres=CTc/postgres
 template1 | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 | =c/postgres          +
           |          |          |             |             | postgres=CTc/postgres
(4 rows)
```

Так же можно проверить таким методом

# NODE1

```
postgres=# select * from pg_stat_replication;
  pid  | usesysid |   usename   | application_name |  client_addr  | client_hostname | client_port |         backend_start         | backend_xmin |   state   | sent_lsn  | write_lsn | flus
h_lsn | replay_lsn | write_lag | flush_lag | replay_lag | sync_priority | sync_state |          reply_time           
-------+----------+-------------+------------------+---------------+-----------------+-------------+-------------------------------+--------------+-----------+-----------+-----------+-----
------+------------+-----------+-----------+------------+---------------+------------+-------------------------------
 23958 |    16384 | replication | walreceiver      | 192.168.57.12 |                 |       35534 | 2023-08-28 16:54:22.767236-03 |          736 | streaming | 0/3000AB8 | 0/3000AB8 | 0/30
00AB8 | 0/3000AB8  |           |           |            |             0 | async      | 2023-08-28 16:57:13.464156-03
(1 row)
```


# NODE2
```
postgres=# select * from pg_stat_wal_receiver;
  pid  |  status   | receive_start_lsn | receive_start_tli | written_lsn | flushed_lsn | received_tli |      last_msg_send_time       |     last_msg_receipt_time     | latest_end_lsn |    
    latest_end_time        | slot_name |  sender_host  | sender_port |                                                                                                                      
                   conninfo                                                                                                                                         
-------+-----------+-------------------+-------------------+-------------+-------------+--------------+-------------------------------+-------------------------------+----------------+----
---------------------------+-----------+---------------+-------------+----------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------------------------------------
 23558 | streaming | 0/3000000         |                 1 | 0/3000AB8   | 0/3000AB8   |            1 | 2023-08-28 16:57:32.042361-03 | 2023-08-28 16:57:32.186893-03 | 0/3000AB8      | 202
3-08-28 16:56:32.010318-03 |           | 192.168.57.11 |        5432 | user=replication password=******** channel_binding=prefer dbname=replication host=192.168.57.11 port=5432 fallback_ap
plication_name=walreceiver sslmode=prefer sslcompression=0 sslsni=1 ssl_min_protocol_version=TLSv1.2 gssencmode=prefer krbsrvname=postgres target_session_attrs=any
(1 row)
```





# BARMAN

Проверяем репликацию: 
```
psql -h 192.168.57.11 -U barman -c "IDENTIFY_SYSTEM" replication=1
Password for user barman: 
      systemid       | timeline |  xlogpos  | dbname 
---------------------+----------+-----------+--------
 7272451926804352910 |        1 | 0/301ACA8 | 
(1 row)
```

Теперь проверим работу barman: 
```
barman switch-wal node1
The WAL file 000000010000000000000003 has been closed on server 'node1'

barman cron
Starting WAL archiving for server node1

barman check node1
Server node1:
	PostgreSQL: OK
	superuser or standard user with backup privileges: OK
	PostgreSQL streaming: OK
	wal_level: OK
	replication slot: OK
	directories: OK
	retention policy settings: OK
2023-08-28 20:50:56,736 [22056] barman.server ERROR: Check 'backup maximum age' failed for server 'node1'
	backup maximum age: FAILED (interval provided: 4 days, latest backup age: No available backups)
	backup minimum size: OK (0 B)
	wal maximum age: OK (no last_wal_maximum_age provided)
	wal size: OK (0 B)
	compression settings: OK
	failed backups: OK (there are 0 failed backups)
2023-08-28 20:50:56,737 [22056] barman.server ERROR: Check 'minimum redundancy requirements' failed for server 'node1'
	minimum redundancy requirements: FAILED (have 0 backups, expected at least 1)
	pg_basebackup: OK
	pg_basebackup compatible: OK
	pg_basebackup supports tablespaces mapping: OK
	systemid coherence: OK (no system Id stored on disk)
	pg_receivexlog: OK
	pg_receivexlog compatible: OK
	receive-wal running: OK
	archiver errors: OK

```


запускаем резервную копию: 
```
barman backup node1
2023-08-28 20:54:07,378 [22092] barman.utils WARNING: Failed opening the requested log file. Using standard error instead.
2023-08-28 20:54:07,580 [22092] barman.server INFO: Ignoring failed check 'backup maximum age' for server 'node1'
2023-08-28 20:54:07,581 [22092] barman.server INFO: Ignoring failed check 'minimum redundancy requirements' for server 'node1'
Starting backup using postgres method for server node1 in /var/lib/barman/node1/base/20230828T205407
2023-08-28 20:54:07,607 [22092] barman.backup INFO: Starting backup using postgres method for server node1 in /var/lib/barman/node1/base/20230828T205407
Backup start at LSN: 0/4000060 (000000010000000000000004, 00000060)
2023-08-28 20:54:07,634 [22092] barman.backup_executor INFO: Backup start at LSN: 0/4000060 (000000010000000000000004, 00000060)
Starting backup copy via pg_basebackup for 20230828T205407
2023-08-28 20:54:07,635 [22092] barman.backup_executor INFO: Starting backup copy via pg_basebackup for 20230828T205407
2023-08-28 20:54:07,677 [22092] barman.backup_executor INFO: pg_basebackup: initiating base backup, waiting for checkpoint to complete
2023-08-28 20:54:07,900 [22092] barman.backup_executor INFO: pg_basebackup: checkpoint completed
2023-08-28 20:54:08,771 [22092] barman.backup_executor INFO: NOTICE:  WAL archiving is not enabled; you must ensure that all required WAL segments are copied through other means to complete the backup
2023-08-28 20:54:08,772 [22092] barman.backup_executor INFO: pg_basebackup: syncing data to disk ...
2023-08-28 20:54:09,344 [22092] barman.backup_executor INFO: pg_basebackup: renaming backup_manifest.tmp to backup_manifest
2023-08-28 20:54:09,347 [22092] barman.backup_executor INFO: pg_basebackup: base backup completed
2023-08-28 20:54:09,347 [22092] barman.backup_executor INFO: 
Copy done (time: 1 second)
2023-08-28 20:54:09,349 [22092] barman.backup_executor INFO: Copy done (time: 1 second)
Finalising the backup.
2023-08-28 20:54:09,352 [22092] barman.backup_executor INFO: Finalising the backup.
This is the first backup for server node1
2023-08-28 20:54:09,404 [22092] barman.backup_executor INFO: This is the first backup for server node1
WAL segments preceding the current backup have been found:
	000000010000000000000003 from server node1 has been removed
2023-08-28 20:54:09,409 [22092] barman.backup_executor INFO: 	000000010000000000000003 from server node1 has been removed
2023-08-28 20:54:09,413 [22092] barman.postgres INFO: Restore point 'barman_20230828T205407' successfully created
Backup size: 42.8 MiB
2023-08-28 20:54:09,747 [22092] barman.backup INFO: Backup size: 42.8 MiB
Backup end at LSN: 0/6000000 (000000010000000000000005, 00000000)
2023-08-28 20:54:09,748 [22092] barman.backup INFO: Backup end at LSN: 0/6000000 (000000010000000000000005, 00000000)
Backup completed (start time: 2023-08-28 20:54:07.637085, elapsed time: 2 seconds)
2023-08-28 20:54:09,749 [22092] barman.backup INFO: Backup completed (start time: 2023-08-28 20:54:07.637085, elapsed time: 2 seconds)
2023-08-28 20:54:09,759 [22092] barman.wal_archiver INFO: Found 2 xlog segments from streaming for node1. Archive all segments in one run.
Processing xlog segments from streaming for node1
	000000010000000000000004
2023-08-28 20:54:09,759 [22092] barman.wal_archiver INFO: Archiving segment 1 of 2 from streaming: node1/000000010000000000000004
	000000010000000000000005
2023-08-28 20:54:09,940 [22092] barman.wal_archiver INFO: Archiving segment 2 of 2 from streaming: node1/000000010000000000000005

```

# Проверка восстановления из бекапов:

## На хосте node1 в psql удаляем базы Otus: 

```
postgres-# \l
                                  List of databases
   Name    |  Owner   | Encoding |   Collate   |    Ctype    |   Access privileges   
-----------+----------+----------+-------------+-------------+-----------------------
 otus      | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 | 
 otus_test | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 | 
 postgres  | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 | 
 template0 | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 | =c/postgres          +
           |          |          |             |             | postgres=CTc/postgres
 template1 | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 | =c/postgres          +
           |          |          |             |             | postgres=CTc/postgres
(5 rows)

postgres-# DROP DATABASE otus;
ERROR:  syntax error at or near "postgres"
LINE 1: postgres=# 
        ^
postgres=# DROP DATABASE otus;
DROP DATABASE
postgres=# DROP DATABASE otus_test; 
DROP DATABASE
postgres=# \l
                                  List of databases
   Name    |  Owner   | Encoding |   Collate   |    Ctype    |   Access privileges   
-----------+----------+----------+-------------+-------------+-----------------------
 postgres  | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 | 
 template0 | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 | =c/postgres          +
           |          |          |             |             | postgres=CTc/postgres
 template1 | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 | =c/postgres          +
           |          |          |             |             | postgres=CTc/postgres
(3 rows)


```

## Далее на хосте barman запустим восстановление: 

```
barman list-backup node1
node1 20230828T205407 - Mon Aug 28 17:54:09 2023 - Size: 42.9 MiB - WAL Size: 0 B

barman recover node1 20230828T205407 /var/lib/pgsql/14/data/ --remote-ssh-comman "ssh postgres@192.168.57.11"

2023-08-28 20:58:35,380 [22133] barman.wal_archiver INFO: No xlog segments found from streaming for node1.
The authenticity of host '192.168.57.11 (192.168.57.11)' can't be established.
ECDSA key fingerprint is SHA256:Hw+nUVpLmzSvYWaYQ6PHDZeFJ0w8qVXtP1c2yev471A.
ECDSA key fingerprint is MD5:04:d7:c9:ca:77:be:8b:31:4b:ca:ca:dd:af:c3:3c:ab.
Are you sure you want to continue connecting (yes/no)? yes
Starting remote restore for server node1 using backup 20230828T205407
2023-08-28 20:58:45,779 [22133] barman.recovery_executor INFO: Starting remote restore for server node1 using backup 20230828T205407
Destination directory: /var/lib/pgsql/14/data/
2023-08-28 20:58:45,781 [22133] barman.recovery_executor INFO: Destination directory: /var/lib/pgsql/14/data/
Remote command: ssh postgres@192.168.57.11
2023-08-28 20:58:45,785 [22133] barman.recovery_executor INFO: Remote command: ssh postgres@192.168.57.11
2023-08-28 20:58:46,421 [22133] barman.recovery_executor WARNING: Unable to retrieve safe horizon time for smart rsync copy: The /var/lib/pgsql/14/data/.barman-recover.info file does not exist
Copying the base backup.
2023-08-28 20:58:47,659 [22133] barman.recovery_executor INFO: Copying the base backup.
2023-08-28 20:58:47,675 [22133] barman.copy_controller INFO: Copy started (safe before None)
2023-08-28 20:58:47,676 [22133] barman.copy_controller INFO: Copy step 1 of 4: [global] analyze PGDATA directory: /var/lib/barman/node1/base/20230828T205407/data/
2023-08-28 20:58:48,564 [22133] barman.copy_controller INFO: Copy step 2 of 4: [global] create destination directories and delete unknown files for PGDATA directory: /var/lib/barman/node1/base/20230828T205407/data/
2023-08-28 20:58:49,353 [22147] barman.copy_controller INFO: Copy step 3 of 4: [bucket 0] starting copy safe files from PGDATA directory: /var/lib/barman/node1/base/20230828T205407/data/
2023-08-28 20:58:51,313 [22147] barman.copy_controller INFO: Copy step 3 of 4: [bucket 0] finished (duration: 1 second) copy safe files from PGDATA directory: /var/lib/barman/node1/base/20230828T205407/data/
2023-08-28 20:58:51,337 [22147] barman.copy_controller INFO: Copy step 4 of 4: [bucket 0] starting copy files with checksum from PGDATA directory: /var/lib/barman/node1/base/20230828T205407/data/
2023-08-28 20:58:51,956 [22147] barman.copy_controller INFO: Copy step 4 of 4: [bucket 0] finished (duration: less than one second) copy files with checksum from PGDATA directory: /var/lib/barman/node1/base/20230828T205407/data/
2023-08-28 20:58:51,957 [22133] barman.copy_controller INFO: Copy finished (safe before None)
Copying required WAL segments.
2023-08-28 20:58:53,733 [22133] barman.recovery_executor INFO: Copying required WAL segments.
2023-08-28 20:58:53,737 [22133] barman.recovery_executor INFO: Starting copy of 1 WAL files 1/1 from WalFileInfo(compression='gzip', name='000000010000000000000005', size=16464, time=1693256049.0936158) to WalFileInfo(compression='gzip', name='000000010000000000000005', size=16464, time=1693256049.0936158)
2023-08-28 20:58:55,172 [22133] barman.recovery_executor INFO: Finished copying 1 WAL files.
Generating archive status files
2023-08-28 20:58:55,176 [22133] barman.recovery_executor INFO: Generating archive status files
Identify dangerous settings in destination directory.
2023-08-28 20:58:56,978 [22133] barman.recovery_executor INFO: Identify dangerous settings in destination directory.

Recovery completed (start time: 2023-08-28 20:58:45.771803+00:00, elapsed time: 11 seconds)
Your PostgreSQL server has been successfully prepared for recovery!

```

## Далее на хосте node1 потребуется перезапустить postgresql-сервер и снова проверить список БД. Базы otus должны вернуться обратно…

```
[root@node1 ~]# systemctl restart postgresql-14.service 
[root@node1 ~]# sudo -u postgres psql
could not change directory to "/root": Permission denied
psql (14.9)
Type "help" for help.

postgres=# \l
                                  List of databases
   Name    |  Owner   | Encoding |   Collate   |    Ctype    |   Access privileges   
-----------+----------+----------+-------------+-------------+-----------------------
 otus      | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 | 
 otus_test | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 | 
 postgres  | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 | 
 template0 | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 | =c/postgres          +
           |          |          |             |             | postgres=CTc/postgres
 template1 | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 | =c/postgres          +
           |          |          |             |             | postgres=CTc/postgres
(5 rows)


```
