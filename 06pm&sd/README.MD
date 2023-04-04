# Размещение своего RPM в своем репозитории

 - Создадим свой RPM пакет на основе nginx с поддержкой openssl
 - Создадим свой репозиторий и разместим там ранее собранный RPM

## _START_

- Для данного задания нам понадобятся следующие установленные пакеты

```bash
yum install -y redhat-lsb-core wget rpmdevtools rpm-build createrepo yum-utils gcc
```

- Для примера возьмем пакет NGINX и соберем его с поддержкой openssl
- Загрузим SRPM пакет NGINX для дальнейшей работы над ним
- При установке такого пакета в домашней директории создается древо каталогов для сборки

```bash
wget https://nginx.org/packages/centos/7/SRPMS/nginx-1.20.2-1.el7.ngx.src.rpm
rpm -i nginx-1.20.2-1.el7.ngx.src.rpm
```

- Также нужно скачать и разархивировать исходники для openssl - они потребуются при сборке

```bash
wget --no-check-certificate https://www.openssl.org/source/openssl-3.0.0.tar.gz
tar -xvf openssl-3.0.0.tar.gz
```

- Заранее поставим все зависимости чтобы в процессе сборки не было ошибок

```bash
yum-builddep -y rpmbuild/SPECS/nginx.spec
```

-  Поправим [spec](https://gist.github.com/lalbrekht/6c4a989758fccf903729fc55531d3a50) файл, чтобы NGINX собирался с необходимыми нам опциями: **--with-openssl=/root/openssl-3.0.0**

vi rpmbuild/SPECS/nginx.spec

```bash
./configure %{BASE_CONFIGURE_ARGS} \
    --with-cc-opt="%{WITH_CC_OPT}" \
    --with-ld-opt="%{WITH_LD_OPT}" \
    --with-openssl=/root/openssl-3.0.0 \
    --with-debug
```
- В нашем случае мы (передали файл в домашнюю директорию гостевой машины при её поднятии) копируем файл из домашней директории в нужную нам
```bash
cp /home/vagrant/nginx.spec rpmbuild/SPECS/nginx.spec
```

> По этой [ссылке](https://nginx.org/ru/docs/configure.html) можно посмотреть все доступные опции для сборки

- Теперь можно приступить к сборке RPM пакета

```bash
rpmbuild -bb rpmbuild/SPECS/nginx.spec

...

hecking for unpackaged file(s): /usr/lib/rpm/check-files /root/rpmbuild/BUILDROOT/nginx-1.20.2-1.el7.ngx.x86_64
Wrote: /root/rpmbuild/RPMS/x86_64/nginx-1.20.2-1.el7.ngx.x86_64.rpm
Wrote: /root/rpmbuild/RPMS/x86_64/nginx-debuginfo-1.20.2-1.el7.ngx.x86_64.rpm
Executing(%clean): /bin/sh -e /var/tmp/rpm-tmp.yXIFE4
+ umask 022
+ cd /root/rpmbuild/BUILD
+ cd nginx-1.20.2
+ /usr/bin/rm -rf /root/rpmbuild/BUILDROOT/nginx-1.20.2-1.el7.ngx.x86_64
+ exit 0

```

- Убедимся, что пакеты создались

```bash

ll rpmbuild/RPMS/x86_64/
total 2588
-rw-r--r--. 1 root root  808416 апр  3 19:17 nginx-1.20.2-1.el7.ngx.x86_64.rpm
-rw-r--r--. 1 root root 1836148 апр  3 19:17 nginx-debuginfo-1.20.2-1.el7.ngx.x86_64.rpm

```

- Теперь можно установить наш пакет и убедиться, что nginx работает

```bash
yum localinstall -y rpmbuild/RPMS/x86_64/nginx-1.20.2-1.el7.ngx.x86_64.rpm

Installed:
  nginx.x86_64 1:1.20.2-1.el7.nginx

Complete!
```

- стартуем

```bash
systemctl enable nginx
systemctl start nginx
systemctl status nginx

● nginx.service - nginx - high performance web server
   Loaded: loaded (/usr/lib/systemd/system/nginx.service; disabled; vendor preset: disabled)
   Active: active (running) since Пн 2023-04-03 19:19:11 UTC; 7s ago
     Docs: http://nginx.org/en/docs/
  Process: 11688 ExecStart=/usr/sbin/nginx -c /etc/nginx/nginx.conf (code=exited, status=0/SUCCESS)
 Main PID: 11689 (nginx)
   CGroup: /system.slice/nginx.service
           ├─11689 nginx: master process /usr/sbin/nginx -c /etc/nginx/nginx.conf
           └─11690 nginx: worker process

апр 03 19:19:11 localhost.localdomain systemd[1]: Starting nginx - high performance web server...
апр 03 19:19:11 localhost.localdomain systemd[1]: Started nginx - high performance web server.

```

- Теперь приступим к созданию своего репозитория. Директория для статики у NGINX по умолчанию /usr/share/nginx/html. Создадим там каталог repo

```bash
mkdir /usr/share/nginx/html/repo
```

- Копируем туда наш собранный RPM и, например, RPM для установки репозитория Percona-Server

```bash
cp rpmbuild/RPMS/x86_64/nginx-1.20.2-1.el7.ngx.x86_64.rpm /usr/share/nginx/html/repo/
```

```bash
wget https://downloads.percona.com/downloads/percona-release/percona-release-1.0-9/redhat/percona-release-1.0-9.noarch.rpm -O /usr/share/nginx/html/repo/percona-release-1.0-9.noarch.rpm

Saving to: «/usr/share/nginx/html/repo/percona-release-1.0-9.noarch.rpm»

100%[=======================================================================================================================================================>] 16 664      --.-K/s   за 0,1s    

2023-04-03 19:24:23 (4,50 MB/s) - ‘/usr/share/nginx/html/repo/percona-release-1.0-9.noarch.rpm’ saved [5222976/5222976]

```

- Инициализируем репозиторий командой

```bash
createrepo -v /usr/share/nginx/html/repo

Spawning worker 0 with 1 pkgs
Spawning worker 1 with 1 pkgs
Worker 0: reading nginx-1.20.2-1.el7.ngx.x86_64.rpm
Worker 1: reading percona-release-1.0-9.noarch.rpm
Workers Finished
Saving Primary metadata
Saving file lists metadata
Saving other metadata
Generating sqlite DBs
```

- Для прозрачности настроим в NGINX доступ к листингу каталога
- В location / в файле /etc/nginx/conf.d/default.conf добавим директиву autoindex on. В результате location будет выглядеть так

vi /etc/nginx/conf.d/default.conf

```bash
    location / {
        root   /usr/share/nginx/html;
        index  index.html index.htm;
        autoindex on;
    }
```

- Проверяем синтаксис и перезапускаем NGINX

```bash
nginx -t
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful

nginx -s reload
```

- Теперь ради интереса можно посмотреть в браузере или выполнить curl

```bash
curl -a http://localhost/repo/

<html>
<head><title>Index of /repo/</title></head>
<body>
<h1>Index of /repo/</h1><hr><pre><a href="../">../</a>
<a href="repodata/">repodata/</a>                                          03-Apr-2023 19:24                   -
<a href="nginx-1.20.2-1.el7.ngx.x86_64.rpm">nginx-1.20.2-1.el7.ngx.x86_64.rpm</a>                  03-Apr-2023 19:23              808416
<a href="<percona-release-1.0-9.noarch.rpm">percona-release-1.0-9.noarch.rpm</a>        16-Feb-2022 15:57             5222976
</pre><hr></body>
</html>

```

- Все готово для того, чтобы протестировать репозиторий
- Добавим его в /etc/yum.repos.d

```bash
cat >> /etc/yum.repos.d/otus.repo << EOF
[otus]
name=otus-linux
baseurl=http://localhost/repo
gpgcheck=0
enabled=1
EOF
```

- Убедимся, что репозиторий подключился и посмотрим что в нем есть

```bash
yum repolist enabled | grep otus
otus                                otus-linux                                 2
```

```bash
yum list | grep nginx
nginx.x86_64                                1:1.20.2-1.el7.ngx         @/nginx-1.20.2-1.el7.ngx.x86_64
```

- Так как NGINX у нас уже стоит, установим репозиторий percona-release

```bash
yum install percona-release -y

Installed:
  percona-release.noarch 0:1.0-9                                                                                                                                                                 

Complite!
```

- Все прошло успешно. В случае если нам потребуется обновить репозиторий (а это делается при каждом добавлении файлов) снова, то выполним команду **createrepo /usr/share/nginx/html/repo/**
