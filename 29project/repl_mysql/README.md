#  Смена Slave to Master (Master to Slave)


Для смены сервера MySQL в режиме репликации Master-Slave из Slave-Master и в случае восстановления работоспособности уже бывшего Master на Slave необходимо:

### Slave to Master

```
> mysql

STOP SLAVE;
RESET MASTER;
CHANGE MASTER TO MASTER_HOST='192.168.10.35';
```

### Master to Slave
```
>mysql

RESET MASTER;
change master to master_host='192.168.10.35', master_port=3306, master_user='repl', master_password='Otus#Linux2023', master_auto_position=2;
START SLAVE;
```

Внести изменения в конфиги сервисов и служб настроенных c бывшего Master на новый, в случаее с Wordpress - файл wp-config.php

```
Change in wordpress config file (wp-config.php) DB Server = 192.168.10.35
```

### Запуск Ansible playbook 

Для автоматизации необходимых действий можно запустить подготовленный [playbook](master-slave.yml).
