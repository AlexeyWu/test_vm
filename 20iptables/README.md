#Сценарии iptables

## Задание

- реализовать knocking port (centralRouter может попасть на ssh inetrRouter через knock)
- добавить inetRouter2, который виден (маршрутизируется (host-only тип сети для виртуалки)) с хоста или форвардится порт через локалхост
- запустить nginx на centralServer
- пробросить 80й порт на inetRouter2 8080
- дефолт в инет оставить через inetRouter


## Проверка

Для проверки доступности nginx выполним локально на ПК: **curl localhost:8080** или если есть X11:

```html
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
html { color-scheme: light dark; }
body { width: 35em; margin: 0 auto;
font-family: Tahoma, Verdana, Arial, sans-serif; }
</style>
</head>
<body>
<h1>Welcome to nginx!</h1>
<p>If you see this page, the nginx web server is successfully installed and
working. Further configuration is required.</p>

<p>For online documentation and support please refer to
<a href="http://nginx.org/">nginx.org</a>.<br/>
Commercial support is available at
<a href="http://nginx.com/">nginx.com</a>.</p>

<p><em>Thank you for using nginx.</em></p>
</body>
</html>
```
![img](./nginx.png)


Настройки для Knock:

```bash
[options]
        logfile = /var/log/knockd.log
        interface = eth1
[openSSH]
        sequence = 7000,8000,9000
        seq_timeout = 30
        tcpflags = syn
        command = /sbin/iptables -I INPUT -s %IP% -p tcp --dport 22 -j ACCEPT
[closeSSH]
        sequence = 7001,8001,9001
        seq_timeout = 30
        tcpflags = syn
        command = /sbin/iptables -D INPUT -s %IP% -p tcp --dport 22 -j ACCEPT
```

Для проверки работоспособности **knocking port** зайдем на ВМ centralRouter и скопируем на него приватный ключ для доступа к inetRouter

- На centralRouter уже установлен клиент knock для удобства
- Проверим, что достук по ssh к inetRouter отсутствует: **ssh vagrant@192.168.255.1**
- Далее введем: **knock 192.168.255.1 7000 8000 9000** и снова попробуем выполнить **ssh vagrant@192.168.255.1**
```
[root@centralRouter ~]# ssh vagrant@192.168.255.1
^C
[root@centralRouter ~]# knock 192.168.255.1 7000 8000 9000
[root@centralRouter ~]# ssh vagrant@192.168.255.1
The authenticity of host '192.168.255.1 (192.168.255.1)' can't be established.
ECDSA key fingerprint is SHA256:wbaOs1Z9jRncUG5BYh8MGbUBGQFWkfd5U1+ndqzk2TE.
ECDSA key fingerprint is MD5:9c:7d:6b:5f:74:0b:6b:89:f0:1d:eb:a9:12:bc:9a:4e.
Are you sure you want to continue connecting (yes/no)? yes
...
```
- Успех!
- После окончания работ на inetRouter, закроем порт 22 выполнив на centralRouter: **knock 192.168.255.1 7001 8001 9001**
- Проверим, что доступ к inetRouter отсутствует: **ssh vagrant@192.168.255.1**
