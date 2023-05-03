# SELinux

1. Запустить nginx на нестандартном порту 3-мя разными способами:

- переключатели setsebool
- добавление нестандартного порта в имеющийся тип
- формирование и установка модуля SELinux

2. Обеспечить работоспособность приложения при включенном selinux.

- развернуть приложенный [стенд](https://github.com/mbfx/otus-linux-adm/tree/master/selinux_dns_problems)
- выяснить причину неработоспособности механизма обновления зоны
- предложить решение (или решения) для данной проблемы
- выбрать одно из решений для реализации, предварительно обосновав выбор
- реализовать выбранное решение и продемонстрировать его работоспособность

### Создаём виртуальную машину

- создаем [_Vagrantfile_](Vagrantfile) и выполняем vagrant up

Результатом выполнения команды vagrant up станет созданная виртуальная машина с установленным nginx, который работает на порту TCP 4881. Порт TCP 4881 уже проброшен до хоста. SELinux включен.

Во время развёртывания стенда попытка запустить nginx завершится с ошибкой:

```bash
systemctl start nginx
Job for nginx.service failed because the control process exited with error code. See "systemctl status nginx.service" and "journalctl -xe" for details.
systemctl status nginx
● nginx.service - The nginx HTTP and reverse proxy server
   Loaded: loaded (/usr/lib/systemd/system/nginx.service; disabled; vendor preset: disabled)
   Active: failed (Result: exit-code) since Вт 2023-05-02 20:24:55 UTC; 46min ago

май 02 20:24:55 selinux systemd[1]: Starting The nginx HTTP and reverse proxy server...
май 02 20:24:55 selinux nginx[4738]: nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
май 02 20:24:55 selinux nginx[4738]: nginx: [emerg] bind() to 0.0.0.0:4881 failed (13: Permission denied)
май 02 20:24:55 selinux nginx[4738]: nginx: configuration file /etc/nginx/nginx.conf test failed
май 02 20:24:55 selinux systemd[1]: nginx.service: control process exited, code=exited status=1
май 02 20:24:55 selinux systemd[1]: Failed to start The nginx HTTP and reverse proxy server.
май 02 20:24:55 selinux systemd[1]: Unit nginx.service entered failed state.
май 02 20:24:55 selinux systemd[1]: nginx.service failed.
```

> Данная ошибка появляется из-за того, что SELinux блокирует работу nginx на нестандартном порту.

- Заходим на сервер: vagrant ssh

> Переходим в root пользователя: sudo -i

## Запуск nginx на нестандартном порту 3-мя разными способами

- Для начала проверим, что в ОС отключен файервол

```bash
systemctl status firewalld

● firewalld.service - firewalld - dynamic firewall daemon
   Loaded: loaded (/usr/lib/systemd/system/firewalld.service; disabled; vendor preset: enabled)
   Active: inactive (dead)
     Docs: man:firewalld(1)
```

- Также можно проверить, что конфигурация nginx настроена без ошибок

```bash
nginx -t

nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful
```

- Далее проверим режим работы SELinux

```bash
getenforce
Enforcing
```

> Должен отображаться режим Enforcing. Данный режим означает, что SELinux будет блокировать запрещенную активность

### Разрешим в SELinux работу nginx на порту TCP 4881 c помощью переключателей setsebool

- Находим в логах (/var/log/audit/audit.log) информацию о блокировании порта

```bash
cat /var/log/audit/audit.log | grep 4881

type=AVC msg=audit(1683059095.148:1428): avc:  denied  { name_bind } for  pid=4738 comm="nginx" src=4881 scontext=system_u:system_r:httpd_t:s0 tcontext=system_u:object_r:unreserved_port_t:s0 tclass=tcp_socket permissive=0

```
- Копируем время, в которое был записан этот лог, и, с помощью утилиты audit2why смотрим информации о запрете

```bash
grep 1683059095.148:1428  /var/log/audit/audit.log | audit2why

type=AVC msg=audit(1683059095.148:1428): avc:  denied  { name_bind } for  pid=4738 comm="nginx" src=4881 scontext=system_u:system_r:httpd_t:s0 tcontext=system_u:object_r:unreserved_port_t:s0 tclass=tcp_socket permissive=0

	Was caused by:
	The boolean nis_enabled was set incorrectly. 
	Description:
	Allow nis to enabled

	Allow access by executing:
	# setsebool -P nis_enabled 1
```

> Утилита audit2why покажет почему трафик блокируется. Исходя из вывода утилиты, мы видим, что нам нужно поменять параметр nis_enabled

- Включим параметр nis_enabled и перезапустим nginx

```bash
setsebool -P nis_enabled on
systemctl restart nginx
systemctl status nginx

● nginx.service - The nginx HTTP and reverse proxy server
   Loaded: loaded (/usr/lib/systemd/system/nginx.service; disabled; vendor preset: disabled)
   Active: active (running) since Вт 2023-05-02 21:14:53 UTC; 14s ago
  Process: 6424 ExecStart=/usr/sbin/nginx (code=exited, status=0/SUCCESS)
  Process: 6422 ExecStartPre=/usr/sbin/nginx -t (code=exited, status=0/SUCCESS)
  Process: 6421 ExecStartPre=/usr/bin/rm -f /run/nginx.pid (code=exited, status=0/SUCCESS)
 Main PID: 6426 (nginx)
   CGroup: /system.slice/nginx.service
           ├─6426 nginx: master process /usr/sbin/nginx
           └─6428 nginx: worker process

май 02 21:14:53 selinux systemd[1]: Starting The nginx HTTP and reverse proxy server...
май 02 21:14:53 selinux nginx[6422]: nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
май 02 21:14:53 selinux nginx[6422]: nginx: configuration file /etc/nginx/nginx.conf test is successful
май 02 21:14:53 selinux systemd[1]: Started The nginx HTTP and reverse proxy server.
```

- Также можно проверить работу nginx из браузера. Заходим в любой браузер на хосте и переходим по адресу <http://127.0.0.1:4881>

- Проверить статус параметра можно с помощью команды

```bash
getsebool -a | grep nis_enabled

nis_enabled --> on
```

- Вернём запрет работы nginx на порту 4881 обратно. Для этого отключим nis_enabled

```bash
setsebool -P nis_enabled off
```

> После отключения nis_enabled служба nginx снова не запустится

### Теперь разрешим в SELinux работу nginx на порту TCP 4881 c помощью добавления нестандартного порта в имеющийся тип

- Поиск имеющегося типа, для http трафика

```bash
semanage port -l | grep http

http_cache_port_t              tcp      8080, 8118, 8123, 10001-10010
http_cache_port_t              udp      3130
http_port_t                    tcp      80, 81, 443, 488, 8008, 8009, 8443, 9000
pegasus_http_port_t            tcp      5988
pegasus_https_port_t           tcp      5989
```

- Добавим порт в тип http_port_t

```bash
semanage port -a -t http_port_t -p tcp 4881

emanage port -l | grep  http_port_t
http_port_t                    tcp      4881, 80, 81, 443, 488, 8008, 8009, 8443, 9000
pegasus_http_port_t            tcp      5988
```

- Теперь перезапустим службу nginx и проверим её работу

```bash
systemctl restart nginx

systemctl status nginx
● nginx.service - The nginx HTTP and reverse proxy server
   Loaded: loaded (/usr/lib/systemd/system/nginx.service; disabled; vendor preset: disabled)
   Active: active (running) since Вт 2023-05-02 21:21:18 UTC; 7s ago
  Process: 6499 ExecStart=/usr/sbin/nginx (code=exited, status=0/SUCCESS)
  Process: 6497 ExecStartPre=/usr/sbin/nginx -t (code=exited, status=0/SUCCESS)
  Process: 6496 ExecStartPre=/usr/bin/rm -f /run/nginx.pid (code=exited, status=0/SUCCESS)
 Main PID: 6501 (nginx)
   CGroup: /system.slice/nginx.service
           ├─6501 nginx: master process /usr/sbin/nginx
           └─6503 nginx: worker process

май 02 21:21:17 selinux systemd[1]: Starting The nginx HTTP and reverse proxy server...
май 02 21:21:18 selinux nginx[6497]: nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
май 02 21:21:18 selinux nginx[6497]: nginx: configuration file /etc/nginx/nginx.conf test is successful
май 02 21:21:18 selinux systemd[1]: Started The nginx HTTP and reverse proxy server.
```

- Также можно проверить работу nginx из браузера. Заходим в любой браузер на хосте и переходим по адресу <http://127.0.0.1:4881>

- Удалить нестандартный порт из имеющегося типа можно с помощью команды

```bash
semanage port -d -t http_port_t -p tcp 4881

semanage port -l | grep http_port_t
http_port_t                    tcp      80, 81, 443, 488, 8008, 8009, 8443, 9000
pegasus_http_port_t            tcp      5988

systemctl restart nginx
Job for nginx.service failed because the control process exited with error code. See "systemctl status nginx.service" and "journalctl -xe" for details.

systemctl status nginx
● nginx.service - The nginx HTTP and reverse proxy server
   Loaded: loaded (/usr/lib/systemd/system/nginx.service; disabled; vendor preset: disabled)
   Active: failed (Result: exit-code) since Вт 2023-05-02 21:22:31 UTC; 10s ago
  Process: 6499 ExecStart=/usr/sbin/nginx (code=exited, status=0/SUCCESS)
  Process: 6524 ExecStartPre=/usr/sbin/nginx -t (code=exited, status=1/FAILURE)
  Process: 6523 ExecStartPre=/usr/bin/rm -f /run/nginx.pid (code=exited, status=0/SUCCESS)
 Main PID: 6501 (code=exited, status=0/SUCCESS)

май 02 21:22:31 selinux systemd[1]: Stopped The nginx HTTP and reverse proxy server.
май 02 21:22:31 selinux systemd[1]: Starting The nginx HTTP and reverse proxy server...
май 02 21:22:31 selinux nginx[6524]: nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
май 02 21:22:31 selinux nginx[6524]: nginx: [emerg] bind() to 0.0.0.0:4881 failed (13: Permission denied)
май 02 21:22:31 selinux nginx[6524]: nginx: configuration file /etc/nginx/nginx.conf test failed
май 02 21:22:31 selinux systemd[1]: nginx.service: control process exited, code=exited status=1
май 02 21:22:31 selinux systemd[1]: Failed to start The nginx HTTP and reverse proxy server.
май 02 21:22:31 selinux systemd[1]: Unit nginx.service entered failed state.
май 02 21:22:31 selinux systemd[1]: nginx.service failed.

```

### Разрешим в SELinux работу nginx на порту TCP 4881 c помощью формирования и установки модуля SELinux

- Попробуем снова запустить nginx

```bash
systemctl start nginx
Job for nginx.service failed because the control process exited with error code. See "systemctl status nginx.service" and "journalctl -xe" for details.
```

- Nginx не запуститься, так как SELinux продолжает его блокировать. Посмотрим логи SELinux, которые относятся к nginx

```bash
grep nginx /var/log/audit/audit.log

type=SOFTWARE_UPDATE msg=audit(1683059094.424:1426): pid=4601 uid=0 auid=1000 ses=2 subj=unconfined_u:unconfined_r:unconfined_t:s0-s0:c0.c1023 msg='sw="nginx-filesystem-1:1.20.1-10.el7.noarch" sw_type=rpm key_enforce=0 gpg_res=1 root_dir="/" comm="yum" exe="/usr/bin/python2.7" hostname=? addr=? terminal=? res=success'
type=SOFTWARE_UPDATE msg=audit(1683059094.811:1427): pid=4601 uid=0 auid=1000 ses=2 subj=unconfined_u:unconfined_r:unconfined_t:s0-s0:c0.c1023 msg='sw="nginx-1:1.20.1-10.el7.x86_64" sw_type=rpm key_enforce=0 gpg_res=1 root_dir="/" comm="yum" exe="/usr/bin/python2.7" hostname=? addr=? terminal=? res=success'
type=AVC msg=audit(1683059095.148:1428): avc:  denied  { name_bind } for  pid=4738 comm="nginx" src=4881 scontext=system_u:system_r:httpd_t:s0 tcontext=system_u:object_r:unreserved_port_t:s0 tclass=tcp_socket permissive=0
type=SYSCALL msg=audit(1683059095.148:1428): arch=c000003e syscall=49 success=no exit=-13 a0=6 a1=558b75d92878 a2=10 a3=7ffedc0a0900 items=0 ppid=1 pid=4738 auid=4294967295 uid=0 gid=0 euid=0 suid=0 fsuid=0 egid=0 sgid=0 fsgid=0 tty=(none) ses=4294967295 comm="nginx" exe="/usr/sbin/nginx" subj=system_u:system_r:httpd_t:s0 key=(null)
type=SERVICE_START msg=audit(1683059095.148:1429): pid=1 uid=0 auid=4294967295 ses=4294967295 subj=system_u:system_r:init_t:s0 msg='unit=nginx comm="systemd" exe="/usr/lib/systemd/systemd" hostname=? addr=? terminal=? res=failed'
type=AVC msg=audit(1683061895.418:1679): avc:  denied  { name_bind } for  pid=6390 comm="nginx" src=4881 scontext=system_u:system_r:httpd_t:s0 tcontext=system_u:object_r:unreserved_port_t:s0 tclass=tcp_socket permissive=0
type=SYSCALL msg=audit(1683061895.418:1679): arch=c000003e syscall=49 success=no exit=-13 a0=6 a1=564d85b6d878 a2=10 a3=7ffdf5dcc240 items=0 ppid=1 pid=6390 auid=4294967295 uid=0 gid=0 euid=0 suid=0 fsuid=0 egid=0 sgid=0 fsgid=0 tty=(none) ses=4294967295 comm="nginx" exe="/usr/sbin/nginx" subj=system_u:system_r:httpd_t:s0 key=(null)
type=SERVICE_START msg=audit(1683061895.421:1680): pid=1 uid=0 auid=4294967295 ses=4294967295 subj=system_u:system_r:init_t:s0 msg='unit=nginx comm="systemd" exe="/usr/lib/systemd/systemd" hostname=? addr=? terminal=? res=failed'
type=SERVICE_START msg=audit(1683062093.697:1685): pid=1 uid=0 auid=4294967295 ses=4294967295 subj=system_u:system_r:init_t:s0 msg='unit=nginx comm="systemd" exe="/usr/lib/systemd/systemd" hostname=? addr=? terminal=? res=success'
type=SERVICE_STOP msg=audit(1683062349.252:1690): pid=1 uid=0 auid=4294967295 ses=4294967295 subj=system_u:system_r:init_t:s0 msg='unit=nginx comm="systemd" exe="/usr/lib/systemd/systemd" hostname=? addr=? terminal=? res=success'
type=AVC msg=audit(1683062349.282:1691): avc:  denied  { name_bind } for  pid=6470 comm="nginx" src=4881 scontext=system_u:system_r:httpd_t:s0 tcontext=system_u:object_r:unreserved_port_t:s0 tclass=tcp_socket permissive=0
type=SYSCALL msg=audit(1683062349.282:1691): arch=c000003e syscall=49 success=no exit=-13 a0=6 a1=560887391878 a2=10 a3=7ffca513bf50 items=0 ppid=1 pid=6470 auid=4294967295 uid=0 gid=0 euid=0 suid=0 fsuid=0 egid=0 sgid=0 fsgid=0 tty=(none) ses=4294967295 comm="nginx" exe="/usr/sbin/nginx" subj=system_u:system_r:httpd_t:s0 key=(null)
type=SERVICE_START msg=audit(1683062349.298:1692): pid=1 uid=0 auid=4294967295 ses=4294967295 subj=system_u:system_r:init_t:s0 msg='unit=nginx comm="systemd" exe="/usr/lib/systemd/systemd" hostname=? addr=? terminal=? res=failed'
type=SERVICE_START msg=audit(1683062478.027:1696): pid=1 uid=0 auid=4294967295 ses=4294967295 subj=system_u:system_r:init_t:s0 msg='unit=nginx comm="systemd" exe="/usr/lib/systemd/systemd" hostname=? addr=? terminal=? res=success'
type=SERVICE_STOP msg=audit(1683062551.830:1700): pid=1 uid=0 auid=4294967295 ses=4294967295 subj=system_u:system_r:init_t:s0 msg='unit=nginx comm="systemd" exe="/usr/lib/systemd/systemd" hostname=? addr=? terminal=? res=success'
type=AVC msg=audit(1683062551.862:1701): avc:  denied  { name_bind } for  pid=6524 comm="nginx" src=4881 scontext=system_u:system_r:httpd_t:s0 tcontext=system_u:object_r:unreserved_port_t:s0 tclass=tcp_socket permissive=0
type=SYSCALL msg=audit(1683062551.862:1701): arch=c000003e syscall=49 success=no exit=-13 a0=6 a1=55b986c40878 a2=10 a3=7fff8a81b2c0 items=0 ppid=1 pid=6524 auid=4294967295 uid=0 gid=0 euid=0 suid=0 fsuid=0 egid=0 sgid=0 fsgid=0 tty=(none) ses=4294967295 comm="nginx" exe="/usr/sbin/nginx" subj=system_u:system_r:httpd_t:s0 key=(null)
type=SERVICE_START msg=audit(1683062551.878:1702): pid=1 uid=0 auid=4294967295 ses=4294967295 subj=system_u:system_r:init_t:s0 msg='unit=nginx comm="systemd" exe="/usr/lib/systemd/systemd" hostname=? addr=? terminal=? res=failed'
type=AVC msg=audit(1683062708.015:1703): avc:  denied  { name_bind } for  pid=6540 comm="nginx" src=4881 scontext=system_u:system_r:httpd_t:s0 tcontext=system_u:object_r:unreserved_port_t:s0 tclass=tcp_socket permissive=0
type=SYSCALL msg=audit(1683062708.015:1703): arch=c000003e syscall=49 success=no exit=-13 a0=6 a1=55ed0a23e878 a2=10 a3=7fffc3fbd900 items=0 ppid=1 pid=6540 auid=4294967295 uid=0 gid=0 euid=0 suid=0 fsuid=0 egid=0 sgid=0 fsgid=0 tty=(none) ses=4294967295 comm="nginx" exe="/usr/sbin/nginx" subj=system_u:system_r:httpd_t:s0 key=(null)
type=SERVICE_START msg=audit(1683062708.018:1704): pid=1 uid=0 auid=4294967295 ses=4294967295 subj=system_u:system_r:init_t:s0 msg='unit=nginx comm="systemd" exe="/usr/lib/systemd/systemd" hostname=? addr=? terminal=? res=failed'
```

- Воспользуемся утилитой audit2allow для того, чтобы на основе логов SELinux сделать модуль, разрешающий работу nginx на нестандартном
порту

```bash
grep nginx /var/log/audit/audit.log | audit2allow -M nginx
******************** IMPORTANT ***********************
To make this policy package active, execute:

semodule -i nginx.pp
```

- Audit2allow сформировал модуль, и сообщил нам команду, с помощью которой можно применить данный модуль

```bash
semodule -i nginx.pp
```

- Попробуем снова запустить nginx

```bash
systemctl start nginx

systemctl status nginx
● nginx.service - The nginx HTTP and reverse proxy server
   Loaded: loaded (/usr/lib/systemd/system/nginx.service; disabled; vendor preset: disabled)
   Active: active (running) since Вт 2023-05-02 21:26:22 UTC; 6s ago
  Process: 6566 ExecStart=/usr/sbin/nginx (code=exited, status=0/SUCCESS)
  Process: 6564 ExecStartPre=/usr/sbin/nginx -t (code=exited, status=0/SUCCESS)
  Process: 6563 ExecStartPre=/usr/bin/rm -f /run/nginx.pid (code=exited, status=0/SUCCESS)
 Main PID: 6568 (nginx)
   CGroup: /system.slice/nginx.service
           ├─6568 nginx: master process /usr/sbin/nginx
           └─6570 nginx: worker process

май 02 21:26:22 selinux systemd[1]: Starting The nginx HTTP and reverse proxy server...
май 02 21:26:22 selinux nginx[6564]: nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
май 02 21:26:22 selinux nginx[6564]: nginx: configuration file /etc/nginx/nginx.conf test is successful
май 02 21:26:22 selinux systemd[1]: Started The nginx HTTP and reverse proxy server.
```

> После добавления модуля nginx запустился без ошибок. При использовании модуля изменения сохранятся после перезагрузки.  
> Просмотр всех установленных модулей: semodule -l

Для удаления модуля воспользуемся командой

```bash
semodule -r nginx
libsemanage.semanage_direct_remove_key: Removing last nginx module (no other nginx module exists at another priority).
```


## Обеспечение работоспособности приложения при включенном SELinux

- Выполним клонирование репозитория

```bash
git clone https://github.com/mbfx/otus-linux-adm.git
Cloning into 'otus-linux-adm'...
remote: Enumerating objects: 558, done.
remote: Counting objects: 100% (456/456), done.
remote: Compressing objects: 100% (303/303), done.
remote: Total 558 (delta 125), reused 396 (delta 74), pack-reused 102
Receiving objects: 100% (558/558), 1.38 MiB | 6.02 MiB/s, done.
Resolving deltas: 100% (140/140), done.

```

- Перейдём в каталог со стендом: cd otus-linux-adm/selinux_dns_problems
- Развернём 2 ВМ с помощью vagrant: vagrant up
- После того, как стенд развернется, проверим ВМ с помощью команды

```bash
vagrant status

Current machine states:

ns01                      running (virtualbox)
client                    running (virtualbox)
```

- Подключимся к клиенту

```bash
vagrant ssh client
```

- Попробуем внести изменения в зону

```bash
nsupdate -k /etc/named.zonetransfer.key

> server 192.168.50.10
> zone ddns.lab
> update add www.ddns.lab. 60 A 192.168.50.15
> send
update failed: SERVFAIL
> quit
```

- Изменения внести не получилось. Посмотрим логи SELinux, чтобы понять в чём может быть проблема
- Для этого воспользуемся утилитой audit2why

```bash
sudo -i
cat /var/log/audit/audit.log | audit2why
```

> Тут мы видим, что на клиенте отсутствуют ошибки

- Не закрывая сессию на клиенте, подключимся к серверу ns01 и проверим логи SELinux

```bash
vagrant ssh ns01
sudo -i

cat /var/log/audit/audit.log | audit2why

type=AVC msg=audit(1683142906.158:2529): avc:  denied  { create } for  pid=7057 comm="isc-worker0000" name="named.ddns.lab.view1.jnl" scontext=system_u:system_r:named_t:s0 tcontext=system_u:object_r:etc_t:s0 tclass=file permissive=0

	Was caused by:
		Missing type enforcement (TE) allow rule.

		You can use audit2allow to generate a loadable module to allow this access.

```

> В логах мы видим, что ошибка в контексте безопасности. Вместо типа named_t используется тип etc_t

- Проверим данную проблему в каталоге /etc/named

```bash
ls -laZ /etc/named
drw-rwx---. root named system_u:object_r:etc_t:s0       .
drwxr-xr-x. root root  system_u:object_r:etc_t:s0       ..
drw-rwx---. root named unconfined_u:object_r:etc_t:s0   dynamic
-rw-rw----. root named system_u:object_r:etc_t:s0       named.50.168.192.rev
-rw-rw----. root named system_u:object_r:etc_t:s0       named.dns.lab
-rw-rw----. root named system_u:object_r:etc_t:s0       named.dns.lab.view1
-rw-rw----. root named system_u:object_r:etc_t:s0       named.newdns.lab

```

> Kонтекст безопасности неправильный. Проблема заключается в том, что конфигурационные файлы лежат в другом каталоге.

- Посмотреть в каком каталоги должны лежать, файлы, чтобы на них распространялись правильные политики SELinux можно с помощью команды

```bash
sudo semanage fcontext -l | grep named

/var/named(/.*)?                                   all files          system_u:object_r:named_zone_t:s0 
/var/named/chroot/var/named(/.*)?                  all files          system_u:object_r:named_zone_t:s0 
```

- Изменим тип контекста безопасности для каталога /etc/named

```bash
chcon -R -t named_zone_t /etc/named

ls -laZ /etc/named
drw-rwx---. root named system_u:object_r:named_zone_t:s0 .
drwxr-xr-x. root root  system_u:object_r:etc_t:s0       ..
drw-rwx---. root named unconfined_u:object_r:named_zone_t:s0 dynamic
-rw-rw----. root named system_u:object_r:named_zone_t:s0 named.50.168.192.rev
-rw-rw----. root named system_u:object_r:named_zone_t:s0 named.dns.lab
-rw-rw----. root named system_u:object_r:named_zone_t:s0 named.dns.lab.view1
-rw-rw----. root named system_u:object_r:named_zone_t:s0 named.newdns.lab

```

- Попробуем снова внести изменения с клиента

```bash
nsupdate -k /etc/named.zonetransfer.key
> server 192.168.50.10
> zone ddns.lab
> update add www.ddns.lab. 60 A 192.168.50.15
> send
> quit

dig www.ddns.lab

; <<>> DiG 9.11.4-P2-RedHat-9.11.4-26.P2.el7_9.13 <<>> www.ddns.lab
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 10267
;; flags: qr aa rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 1, ADDITIONAL: 2

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4096
;; QUESTION SECTION:
;www.ddns.lab.			IN	A

;; ANSWER SECTION:
www.ddns.lab.		60	IN	A	192.168.50.15

;; AUTHORITY SECTION:
ddns.lab.		3600	IN	NS	ns01.dns.lab.

;; ADDITIONAL SECTION:
ns01.dns.lab.		3600	IN	A	192.168.50.10

;; Query time: 1 msec
;; SERVER: 192.168.50.10#53(192.168.50.10)
;; WHEN: Ср май 03 19:49:45 UTC 2023
;; MSG SIZE  rcvd: 96


```

- Видим, что изменения применились. Попробуем перезагрузить хосты и ещё раз сделать запрос с помощью dig

```bash
dig @192.168.50.10 www.ddns.lab

; <<>> DiG 9.11.4-P2-RedHat-9.11.4-26.P2.el7_9.8 <<>> @192.168.50.10 www.ddns.lab
; (1 server found)
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 30151
;; flags: qr aa rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 1, ADDITIONAL: 2

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4096
;; QUESTION SECTION:
;www.ddns.lab.                  IN      A

;; ANSWER SECTION:
www.ddns.lab.           60      IN      A       192.168.50.15

;; AUTHORITY SECTION:
ddns.lab.               3600    IN      NS      ns01.dns.lab.

;; ADDITIONAL SECTION:
ns01.dns.lab.           3600    IN      A       192.168.50.10

;; Query time: 0 msec
;; SERVER: 192.168.50.10#53(192.168.50.10)
;; WHEN: Wed Jan 19 21:54:43 UTC 2022
;; MSG SIZE  rcvd: 96
```

> Всё правильно. После перезагрузки настройки сохранились.

- Для того, чтобы вернуть правила обратно, можно ввести команду

```bash
restorecon -v -R /etc/named

restorecon reset /etc/named context system_u:object_r:named_zone_t:s0->system_u:object_r:etc_t:s0
restorecon reset /etc/named/named.dns.lab context system_u:object_r:named_zone_t:s0->system_u:object_r:etc_t:s0
restorecon reset /etc/named/named.dns.lab.view1 context system_u:object_r:named_zone_t:s0->system_u:object_r:etc_t:s0
restorecon reset /etc/named/dynamic context unconfined_u:object_r:named_zone_t:s0->unconfined_u:object_r:etc_t:s0
restorecon reset /etc/named/dynamic/named.ddns.lab context system_u:object_r:named_zone_t:s0->system_u:object_r:etc_t:s0
restorecon reset /etc/named/dynamic/named.ddns.lab.view1 context system_u:object_r:named_zone_t:s0->system_u:object_r:etc_t:s0
restorecon reset /etc/named/dynamic/named.ddns.lab.view1.jnl context system_u:object_r:named_zone_t:s0->system_u:object_r:etc_t:s0
restorecon reset /etc/named/named.newdns.lab context system_u:object_r:named_zone_t:s0->system_u:object_r:etc_t:s0
restorecon reset /etc/named/named.50.168.192.rev context system_u:object_r:named_zone_t:s0->system_u:object_r:etc_t:s0
```

