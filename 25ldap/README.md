## LDAP

### Задача

Описание домашнего задания
1) Установить FreeIPA
2) Написать Ansible-playbook для конфигурации клиента

Дополнительное задание
3)* Настроить аутентификацию по SSH-ключам
4)** Firewall должен быть включен на сервере и на клиенте


### Дополнительные сведения
На Centos 7 необходимо обновить nss, без него настройка падает
https://access.redhat.com/solutions/4350171


```
  - name: Upgrade nss
    ansible.builtin.yum:
      name: 'nss'
      state: latest
```

Параметры для развёртывания ipa:
-r REALM_NAME, --realm=REALM_NAME
    The Kerberos realm name for the IPA server
-n DOMAIN_NAME, --domain=DOMAIN_NAME
    Your DNS domain name
-p DM_PASSWORD, --ds-password=DM_PASSWORD
    The password to be used by the Directory Server for the Directory Manager user
-P MASTER_PASSWORD, --master-password=MASTER_PASSWORD
    The kerberos master password (normally autogenerated)
-a ADMIN_PASSWORD, --admin-password=ADMIN_PASSWORD
    The password for the IPA admin user
--hostname=HOST_NAME
    The fully-qualified DNS name of this server. If the hostname does not match system hostname, the system hostname will be updated accordingly to prevent service failures.
--ip-address=IP_ADDRESS
    The IP address of this server. If this address does not match the address the host resolves to and --setup-dns is not selected the installation will fail. If the server hostname is not resolvable, a record for the hostname and IP_ADDRESS is added to /etc/hosts. 
-N, --no-ntp

--setup-dns
    Generate a DNS zone if it does not exist already and configure the DNS server. This option requires that you either specify at least one DNS forwarder through the --forwarder option or use the --no-forwarders option.



### Решение

#### Открываем нужные порты для


#### Часть плейбука для настройки сервера и создания учетной записи пользователя

```
- name: Config IPA Server
  hosts: ipa.otus.lan
  become: yes
  tasks:

  - name: Upgrade nss
    ansible.builtin.yum:
      name: 'nss'
      state: latest

  - name: install packages
    ansible.builtin.yum:
      name:
        - ipa-server
        - ipa-server-dns



  - name: delete freeipa-server config
    command: |
      ipa-server-install -U \
      --uninstall \

  - name: configure freeipa
    command: |
      ipa-server-install -U \
      -r OTUS.LAN \
      -n otus.lan \
      -p otus1234 \
      -a otus1234 \
      --hostname=ipa.otus.lan \
      --ip-address=192.168.57.10 \
      --mkhomedir \
      --no-ntp \


  - ipa_user:
      name: test
      givenname: Teste
      sn: 1
      password: test1234
      loginshell: /bin/bash
      ipa_host: ipa.otus.lan
      ipa_user: admin
      ipa_pass: otus1234

```


#### Часть плейбука для настройки клиента

```
- name: Config Clients
  hosts: client1.otus.lan,client2.otus.lan
  become: yes
  tasks:

  - name: Upgrade nss client
    ansible.builtin.yum:
      name: 'nss'
      state: latest
#Установка клиента Freeipa
  - name: install module ipa-client
    ansible.builtin.yum:
      name:
        - freeipa-client
      state: present
      update_cache: true



  - name: configure ipa-client
    command: |
      ipa-client-install -U \
      --principal admin@OTUS.LAN \
      --password otusotus \
      --server ipa.otus.lan \
      --domain otus.lan \
      --realm OTUS.LAN \
      --mkhomedir \
      --force-join
                            
```


#### Проверяем, подключение клиента

```
WARNING: ntpd time&date synchronization service will not be configured as
conflicting service (chronyd) is enabled
Use --force-ntpd option to disable it and force configuration of ntpd

Client hostname: client1.otus.lan
Realm: OTUS.LAN
DNS Domain: otus.lan
IPA Server: ipa.otus.lan
BaseDN: dc=otus,dc=lan

Skipping synchronizing time with NTP server.
Successfully retrieved CA cert
    Subject:     CN=Certificate Authority,O=OTUS.LAN
    Issuer:      CN=Certificate Authority,O=OTUS.LAN
    Valid From:  2023-08-09 03:02:00
    Valid Until: 2043-08-09 03:02:00

Enrolled in IPA realm OTUS.LAN
Created /etc/ipa/default.conf
New SSSD config will be created
Configured sudoers in /etc/nsswitch.conf
Configured /etc/sssd/sssd.conf
trying https://ipa.otus.lan/ipa/json
[try 1]: Forwarding 'schema' to json server 'https://ipa.otus.lan/ipa/json'
trying https://ipa.otus.lan/ipa/session/json
[try 1]: Forwarding 'ping' to json server 'https://ipa.otus.lan/ipa/session/json'
[try 1]: Forwarding 'ca_is_enabled' to json server 'https://ipa.otus.lan/ipa/session/json'
Systemwide CA database updated.
Hostname (client1.otus.lan) does not have A/AAAA record.
Failed to update DNS records.
Missing A/AAAA record(s) for host client1.otus.lan: 192.168.57.11.
Missing reverse record(s) for address(es): 192.168.57.11.
Adding SSH public key from /etc/ssh/ssh_host_rsa_key.pub
Adding SSH public key from /etc/ssh/ssh_host_ecdsa_key.pub
Adding SSH public key from /etc/ssh/ssh_host_ed25519_key.pub
[try 1]: Forwarding 'host_mod' to json server 'https://ipa.otus.lan/ipa/session/json'
Could not update DNS SSHFP records.
SSSD enabled
Configured /etc/openldap/ldap.conf
Configured /etc/ssh/ssh_config
Configured /etc/ssh/sshd_config
Configuring otus.lan as NIS domain.
Configured /etc/krb5.conf for IPA realm OTUS.LAN
Client configuration complete.
The ipa-client-install command was successful
```

#### Добавляем запись в /etc/hosts на localhost

```
root@ubuntu:/home/mity/Documents/OTUS_Linux_Prof/Lesson36_VLAN_LACP# cat /etc/hosts

192.168.57.10 ipa.otus.lan
```
#### Проверяем через веб-интерфейс, что учетка создалась и ПК подключились к домену.


![pict1](pict1.png)

![pict2](pict2.png)


#### Проверяем на сервере выдачу билетов и запрашиваем список билетов

```
[[root@ipa ~]# kinit admin
Password for admin@OTUS.LAN: 
[root@ipa ~]# klist
Ticket cache: KEYRING:persistent:0:0
Default principal: admin@OTUS.LAN

Valid starting       Expires              Service principal
09.08.2023 03:13:25  10.08.2023 03:13:22  krbtgt/OTUS.LAN@OTUS.LAN

```

#### Пробуем залогиниться созданной в ipa учёткой с клиента

```
[vagrant@client1 ~]$ sudo -i
[root@client1 ~]# kinit tester1
Password for tester1@OTUS.LAN:
Password expired.  You must change it now.
Enter new password:
Enter it again:
[root@client1 ~]#
```