# Systemd commands


# System V service management
service nginx start|stop|reload|restart

/etc/init.d/nginx start|stop|reload|restart

 update-rc.d nginx enable|remove

chkconfig nginx on

# Upstart
initctl start|stop apache2
start|stop apache2

##################
# Systemd
##################

# Смотрим родителей процессов
ps -ef | head

# Статус
systemctl status

# Контрольные группы
systemd-cgls

# Скорость загрузки системы
systemd-analyze [time]
systemd-analyze blame
systemd-analyze critical-chain
systemctl list-dependencies

# Управление режимами
systemctl start $target.target
systemctl $target
systemctl reboot || systemctl rescue || systemctl poweroff

# Работа с журналами
journalctl -p err

journalctl --since yesterday

journalctl --since 20:00 --until now

journalctl --since 19:00 --until "1 hour ago"
journalctl --since "2017-04-07 20:30:00"
journalctl --since "2017-04-07 20:30:00" --until "2017-04-08 15:25:00"
journalctl -u ssh.service
journalctl -u ssh.service --since yesterday

# Конфигурация


# Шаблоны
cat /lib/systemd/system/getty@.service
systemctl status getty@tty1.service

# Сgroups
ps -afxo pid,user,comm,cgroup
systemd-cgtop
ls -l /lib/systemd/system/*.slice

# Вывод списков
systemctl --help | grep list-

systemctl list-unit-files
systemctl list-dependencies
systemctl list-units
systemctl list-timers

systemctl --help | grep is-

systemctl is-enabled nginx
systemctl is-active ssh

# Управление юнитами
systemctl status|reload|start|stop|restart unit.serivce

# Управление автостартом
systemctl enable|disable unit.serivce
systemctl mask|unmask unit.serivce

# Обновление юнитов
systemctl daemon-reload

# Просмотр и модификация
systemctl cat|show unit.serivce
systemctl edit --full unit.serivce

# Просмотр изменений по юнитам
systemd-delta --type=extended

# Ограничения в systemd
man systemd.exec

[Service]
LimitAS=100M
LimitFSIZE=20M

man systemd.resource-control

[Service]
MemoryLimit=2M

# Создаём собственный сервис
sudo touch /etc/systemd/system/test.service
sudo chmod 664 /etc/systemd/system/test.service

sudo nano /etc/systemd/system/test.service

###
[Unit]
Description=Test service

[Service]
ExecStart=ping ya.ru


[Install]
WantedBy=multi-user.target

###





