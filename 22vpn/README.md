#VPN

## Задание

- Между двумя виртуалками поднять vpn в режимах:
  - tun
  - tap

Описать в чём разница, замерить скорость между виртуальными машинами в туннелях, сделаь вывод об отличающихся показателях скорости.

- Поднять RAS на базе OpenVPN с клиентскими сертификатами, подключиться с локальной машины на виртуалку

## TUN/TAP режимы VPN

### Для выполнения первого пункта необходимо написать Vagrantfile, который будет поднимать 2 виртуальные машины server и client

Типовой Vagrantfile для данной задачи:

```
# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure(2) do |config|
  config.vm.box = "centos/7"
  config.vm.define "server" do |server|
    server.vm.hostname = "server.loc"
    server.vm.network "private_network", ip: "192.168.56.10"
  end
  config.vm.define "client" do |client|
    client.vm.hostname = "client.loc"
    client.vm.network "private_network", ip: "192.168.56.20"
  end
    
end
```

> Можно использовать готовый playbook, который раскатает сервер и клиент OpenVPN дополнив наш Vagrantfile

```bash
    config.vm.provision "ansible" do |ansible|
        ansible.playbook = "playbook.yml"
        ansible.become = true
        ansible.limit = "all"
        ansible.host_key_checking = "false"
    end  
```

### После запуска машин из Vagrantfile выполняем следующие действия на server и client машинах

- устанавливаем epel репозиторий

```bash
yum install -y epel-release
```

- устанавливаем пакет openvpn, easy-rsa и iperf3

```bash
yum install -y openvpn iperf3
```

- Отключаем SELinux (при желании можно написать правило для openvpn)

```bash
setenforce 0
```

> Работает до ребута

### Настройка openvpn сервера

- создаем файл ключ

```bash
openvpn --genkey --secret /etc/openvpn/static.key
```

- создаём конфигурационный файл vpn-сервера

```bash
vi /etc/openvpn/server.conf

dev tap
ifconfig 10.10.10.1 255.255.255.0
topology subnet
secret /etc/openvpn/static.key
comp-lzo
status /var/log/openvpn-status.log
log /var/log/openvpn.log
verb 3
```

- Запускаем openvpn сервер и добавлāем в автозагрузку

```bash
systemctl start openvpn@server
systemctl enable openvpn@server
```

### Настройка openvpn клиента

```bash
vi /etc/openvpn/server.conf

dev tap
remote 192.168.56.10
ifconfig 10.10.10.2 255.255.255.0
topology subnet
route 192.168.56.0 255.255.255.0
secret /etc/openvpn/static.key
comp-lzo
status /var/log/openvpn-status.log
log /var/log/openvpn.log
verb 3
```

- На сервер клиента в директории /etc/openvpn/ скопируем файл-ключ static.key, который был создан на сервере

- Запускаем openvpn клиент и добавляем в автозагрузку

```bash
systemctl start openvpn@server
systemctl enable openvpn@server
```

### Далее необходимо замерить скорость в туннеле

- на openvpn сервере запускаем iperf3 в режиме сервера

```bash
iperf3 -s &
```

- на openvpn клиенте запускаем iperf3 в режиме клиента и замеряем скорость в туннеле

```bash
iperf3 -c 10.10.10.1 -t 40 -i 5

Connecting to host 10.10.10.1, port 5201
[  4] local 10.10.10.2 port 60082 connected to 10.10.10.1 port 5201
[ ID] Interval           Transfer     Bandwidth       Retr  Cwnd
[  4]   0.00-5.00   sec  59.6 MBytes   100 Mbits/sec   57    253 KBytes       
[  4]   5.00-10.01  sec  58.0 MBytes  97.2 Mbits/sec   42    182 KBytes       
[  4]  10.01-15.00  sec  56.1 MBytes  94.2 Mbits/sec   16    286 KBytes       
[  4]  15.00-20.00  sec  59.6 MBytes  99.9 Mbits/sec   81    206 KBytes       
[  4]  20.00-25.00  sec  59.2 MBytes  99.3 Mbits/sec   38    130 KBytes       
[  4]  25.00-30.00  sec  60.4 MBytes   101 Mbits/sec   20    253 KBytes       
[  4]  30.00-35.01  sec  59.6 MBytes  99.8 Mbits/sec   41    214 KBytes       
[  4]  35.01-40.00  sec  58.8 MBytes  98.9 Mbits/sec   15    272 KBytes       
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bandwidth       Retr
[  4]   0.00-40.00  sec   471 MBytes  98.8 Mbits/sec  310             sender
[  4]   0.00-40.00  sec   470 MBytes  98.7 Mbits/sec                  receiver

iperf Done.

```

### Повторяем пункты 1-5 для режима работы tun. Конфигурационные файлы сервера и клиента изменяться только в директиве dev. Делаем выводы о режимах, их достоинствах и недостатках

```bash
Connecting to host 10.10.10.1, port 5201
[  4] local 10.10.10.2 port 60086 connected to 10.10.10.1 port 5201
[ ID] Interval           Transfer     Bandwidth       Retr  Cwnd
[  4]   0.00-5.00   sec  58.5 MBytes  98.2 Mbits/sec   34    233 KBytes       
[  4]   5.00-10.01  sec  61.7 MBytes   103 Mbits/sec   39    156 KBytes       
[  4]  10.01-15.00  sec  58.8 MBytes  98.7 Mbits/sec   93    219 KBytes       
[  4]  15.00-20.00  sec  57.9 MBytes  97.1 Mbits/sec   31    172 KBytes       
[  4]  20.00-25.00  sec  58.9 MBytes  98.8 Mbits/sec   52    218 KBytes       
[  4]  25.00-30.00  sec  59.4 MBytes  99.7 Mbits/sec   26    188 KBytes       
[  4]  30.00-35.00  sec  57.2 MBytes  96.0 Mbits/sec   53    205 KBytes       
[  4]  35.00-40.00  sec  59.1 MBytes  99.1 Mbits/sec   74    143 KBytes       
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bandwidth       Retr
[  4]   0.00-40.00  sec   471 MBytes  98.9 Mbits/sec  402             sender
[  4]   0.00-40.00  sec   471 MBytes  98.7 Mbits/sec                  receiver

iperf Done.

```

> В tun режиме чуть быстрее при проведение теста на виртуалках, но и много потерь пакетов.

## RAS на базе OpenVPN

Для выполнения данного задания можно восполязоваться Vagrantfile из 1 задания, только убрать 1 ВМ.

### После запуска ВМ отключаем SELinux или создаём правило для него

```bash
setenforce 0
```

### Устанавливаем репозиторий EPEL

```bash
yum install -y epel-release
```

### Устанавливаем необходимые пакеты

```bash
yum install -y openvpn easy-rsa
```

### Переходим в директорию /etc/openvpn/ и инициализируем pki

```bash
cd /etc/openvpn/
/usr/share/easy-rsa/3.0.8/easyrsa init-pki
```

### Сгенерируем необходимые ключи и сертификаты для сервера

```bash
echo 'rasvpn' | /usr/share/easy-rsa/3.0.8/easyrsa build-ca nopass
echo 'rasvpn' | /usr/share/easy-rsa/3.0.8/easyrsa gen-req server nopass
echo 'yes' | /usr/share/easy-rsa/3.0.8/easyrsa sign-req server server
/usr/share/easy-rsa/3.0.8/easyrsa gen-dh
openvpn --genkey --secret ta.key
```

### Сгенерируем сертификаты для клиента

```bash
echo 'client' | /usr/share/easy-rsa/3.0.8/easyrsa gen-req client nopass
echo 'yes' | /usr/share/easy-rsa/3.0.8/easyrsa sign-req client client
```

### Создадим конфигурационный файл /etc/openvpn/server.conf

```bash
port 1207
proto udp
dev tun
ca /etc/openvpn/pki/ca.crt
cert /etc/openvpn/pki/issued/server.crt
key /etc/openvpn/pki/private/server.key
dh /etc/openvpn/pki/dh.pem
server 10.10.10.0 255.255.255.0
#route 192.168.56.0 255.255.255.0
push "route 192.168.56.0 255.255.255.0"
ifconfig-pool-persist ipp.txt
client-to-client
client-config-dir /etc/openvpn/client
keepalive 10 120
comp-lzo
persist-key
persist-tun
status /var/log/openvpn-status.log
log /var/log/openvpn.log
verb 3
```

### Зададим параметр iroute для клиента

```bash
echo 'iroute 192.168.56.0 255.255.255.0' > /etc/openvpn/client/client
```

### Запускаем openvpn сервер и добавляем в автозагрузку

```bash
systemctl start openvpn@server
systemctl enable openvpn@server
```

### Скопируем следующие файлы сертификатов и ключ для клиента на хостмашину

```bash
/etc/openvpn/pki/ca.crt
/etc/openvpn/pki/issued/client.crt
/etc/openvpn/pki/private/client.key
```

> Файлы рекомендуется расположить в той же директории, что и client.conf

### Создадим конфигурационный файл клиента client.conf на хост-машине

```bash
dev tun
proto udp
remote 192.168.56.10 1207
client
resolv-retry infinite
ca ./ca.crt
cert ./client.crt
key ./client.key
#route 192.168.56.0 255.255.255.0
persist-key
persist-tun
comp-lzo
verb 3
```

В этом конфигурационном файле указано, что файлы сертификатов располагаются в директории, где располагается client.conf. Но при желании можно разместить сертификаты в других директориях и в конфиге скорректировать пути.

### После того, как все готово, подключаемся к openvpn сервер с хост-машины

```bash
openvpn --config client.conf
```

### При успешном подключении проверяем пинг в внутреннему IP адресу сервера в туннеле

```bash
ping -c 4 10.10.10.1

ING 10.10.10.1 (10.10.10.1) 56(84) bytes of data.
64 bytes from 10.10.10.1: icmp_seq=1 ttl=64 time=1.38 ms
64 bytes from 10.10.10.1: icmp_seq=2 ttl=64 time=1.27 ms
64 bytes from 10.10.10.1: icmp_seq=3 ttl=64 time=1.39 ms
^C
--- 10.10.10.1 ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 2004ms
rtt min/avg/max/mdev = 1.279/1.354/1.394/0.053 ms

```

### Также проверяем командой ip r (netstat -rn) на хостовой машине, что сеть туннеля импортирована в таблицу маршрутизации

```bash
default via 10.0.2.2 dev eth0 proto dhcp metric 101 
10.0.2.0/24 dev eth0 proto kernel scope link src 10.0.2.15 metric 101 
10.10.10.0/24 via 10.10.10.5 dev tun0 
10.10.10.5 dev tun0 proto kernel scope link src 10.10.10.6 
192.168.56.0/24 dev eth1 proto kernel scope link src 192.168.56.11 metric 100 
```
