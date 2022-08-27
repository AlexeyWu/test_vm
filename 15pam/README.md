                     # PAM


- _Vagranfile_ - файл конфигурации для создания VM для работы с PAM

## Создаём пользователя otusadm и otus, а так же 2й строкой пароли им: 
```
sudo useradd otusadm && sudo useradd otus
echo "Otus2022!" | sudo passwd --stdin otusadm && echo "Otus2022!" | sudo passwd --stdin otus
```
## Создаём группу admin: 
```
sudo groupadd -f admin
```
## Добавляем пользователей vagrant,root и otusadm в группу admin:
```
usermod otusadm -a -G admin && usermod root -a -G admin && usermod vagrant -a -G admin
```
## Проверим, что пользователи root, vagrant и otusadm есть в группе admin:
```
[root@pam ~]# cat /etc/group | grep admin
printadmin:x:997:
admin:x:1003:otusadm,root,vagrant
```
## Создадим файл-скрипт /usr/local/bin/login.sh
```
vi /usr/local/bin/login.sh
```
```
#!/bin/bash
#Первое условие: если день недели суббота или воскресенье
if [ $(date +%a) = "Sat" ] || [ $(date +%a) = "Sun" ]; then
 #Второе условие: входит ли пользователь в группу admin
 if getent group admin | grep -qw "$PAM_USER"; then
        #Если пользователь входит в группу admin, то он может подключиться
        exit 0
      else
        #Иначе ошибка (не сможет подключиться)
        exit 1
    fi
  #Если день не выходной, то подключиться может любой пользователь
  else
    exit 0
fi

```
## Добавим права на исполнение файла: 
```
chmod +x /usr/local/bin/login.sh
```
## Укажем в файле /etc/pam.d/sshd модуль pam_exec и наш скрипт:
```
#%PAM-1.0
auth       required     pam_sepermit.so
auth       substack     password-auth
auth       include      postlogin
-auth      optional     pam_reauthorize.so prepare
account    required     pam_exec.so /usr/local/bin/login.sh
account    required     pam_nologin.so
account    include      password-auth
password   include      password-auth
# pam_selinux.so close should be the first session rule
session    required     pam_selinux.so close
session    required     pam_loginuid.so
# pam_selinux.so open should only be followed by sessions to be executed in the user context
session    required     pam_selinux.so open env_params
session    required     pam_namespace.so
session    optional     pam_keyinit.so force revoke
session    optional     pam_motd.so
session    include      password-auth
session    include      postlogin
```
## Чтобы выставить дату нам надо отключить NTP , чтобы не происходила синхронизация времени
## с NTP сервером , когда мы его поменяем. Выключаем и меняем уже двту на выходной, чтобы
## прговерить работу скрипта при логине
```
sudo date 082712302022.00
```
## проверяем с хоста подключение к гостевой машине
```
ssh otus@192.168.57.10
otus@192.168.57.10's password: 
/usr/local/bin/login.sh failed: exit code 1
Connection closed by 192.168.57.10 port 22

ssh otusadm@192.168.57.10
otusadm@192.168.57.10's password: 
Last failed login: Mon May 29 22:22:06 UTC 2023 from 192.168.57.1 on ssh:notty
There were 8 failed login attempts since the last successful login.
Last login: Mon May 29 22:03:41 2023 from 192.168.57.1
[otusadm@pam ~]$ exit
logout
Connection to 192.168.57.10 closed.
```

