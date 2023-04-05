#!/bin/sh

echo =============================
echo ---------timer---------------
echo =============================

sudo -i

#добавляем данные в файл
cat <<'EOF' >/etc/sysconfig/watchlog
WORD="ALERT"
LOG=/var/log/watchlog.log
EOF

#добавляем данные в файл
cat <<'EOF' >/var/log/watchlog.log
Add other string to file
4353 
ALERT = nuzhnoe nam slovo
EOF

#Создадим скрипт vi /opt/watchlog.sh
cat <<'EOF' >/opt/watchlog.sh
#!/bin/bash
WORD=$1
LOG=$2
DATE=`date`
if grep $WORD $LOG &> /dev/null
then
  logger "$DATE: I found word, Master!"
else
  exit 0
fi
EOF

#делаем скрипт исполняемым
sudo chmod +x /opt/watchlog.sh

#Создадим юнит для сервиса watchlog
cat <<'EOF' >/etc/systemd/system/watchlog.service
[Unit]
Description=My watchlog service
[Service]
Type=oneshot
EnvironmentFile=/etc/sysconfig/watchlog
ExecStart=/opt/watchlog.sh $WORD $LOG
EOF

#Создадим юнит для таймера
cat <<'EOF' >/etc/systemd/system/watchlog.timer
[Unit]
Description=Run watchlog script every 30 second
[Timer]
# Run every 30 second
OnUnitActiveSec=30
Unit=watchlog.service
[Install]
WantedBy=multi-user.target
EOF

#Запустим таймер
systemctl start watchlog.timer
systemctl start watchlog.service	

#Убедимся в результате
echo timeout 1m tail -f /var/log/messages


echo ============================
echo ---------spawn-fcgi---------
echo ============================

yum install epel-release -y && yum install spawn-fcgi php php-cli mod_fcgid httpd -y

#замена строчек в файле
sed -i '/#SOCKET=\/var\/run\/php-fcgi.sock/s/^#\+//' /etc/sysconfig/spawn-fcgi
sed -i '/#OPTIONS="-u apache -g apache -s $SOCKET -S -M 0600 -C 32 -F 1 -P \/var\/run\/spawn-fcgi.pid -- \/usr\/bin\/php-cgi"/s/^#\+//' /etc/sysconfig/spawn-fcgi


touch /etc/systemd/system/spawn-fcgi.service

#Unit file


cat <<'EOF' >/etc/systemd/system/spawn-fcgi.service
[Unit]
Description=Spawn-fcgi startup service by Otus
After=network.target
[Service]
Type=simple
PIDFile=/var/run/spawn-fcgi.pid
EnvironmentFile=/etc/sysconfig/spawn-fcgi
ExecStart=/usr/bin/spawn-fcgi -n $OPTIONS
KillMode=process
[Install]
WantedBy=multi-user.target
EOF

systemctl start spawn-fcgi
sleep 10
systemctl status spawn-fcgi
sleep 10
echo ====================================================
echo ---------httpd run multiple instances---------------
echo ====================================================

cat <<'EOF' >/etc/systemd/system/httpd@second.service
[Unit]
Description=The Apache HTTP Server
After=network.target remote-fs.target nss-lookup.target
Documentation=man:httpd(8)
Documentation=man:apachectl(8)
[Service]
Type=notify
EnvironmentFile=/etc/sysconfig/httpd-%I
ExecStart=/usr/sbin/httpd $OPTIONS -DFOREGROUND
ExecReload=/usr/sbin/httpd $OPTIONS -k graceful
ExecStop=/bin/kill -WINCH ${MAINPID}
KillSignal=SIGCONT
PrivateTmp=true
[Install]
WantedBy=multi-user.target
EOF

cat <<'EOF' >/etc/systemd/system/httpd@first.service
[Unit]
Description=The Apache HTTP Server
After=network.target remote-fs.target nss-lookup.target
Documentation=man:httpd(8)
Documentation=man:apachectl(8)
[Service]
Type=notify
EnvironmentFile=/etc/sysconfig/httpd-%I
ExecStart=/usr/sbin/httpd $OPTIONS -DFOREGROUND
ExecReload=/usr/sbin/httpd $OPTIONS -k graceful
ExecStop=/bin/kill -WINCH ${MAINPID}
KillSignal=SIGCONT
PrivateTmp=true
[Install]
WantedBy=multi-user.target
EOF

#Добавим параметр %I к EnvironmentFile=/etc/sysconfig/httpd
sed -i 's/EnvironmentFile=\/etc\/sysconfig\/httpd/EnvironmentFile=\/etc\/sysconfig\/httpd-%I/' /usr/lib/systemd/system/httpd.service


#
cat <<'EOF' >/etc/sysconfig/httpd-first
OPTIONS=-f conf/first.conf
EOF

cat <<'EOF' >/etc/sysconfig/httpd-second
OPTIONS=-f conf/second.conf
EOF

cp /etc/httpd/conf/httpd.conf /etc/httpd/conf/first.conf                              
cp /etc/httpd/conf/httpd.conf /etc/httpd/conf/second.conf

sed -i 's/Listen 80/Listen 8080/' /etc/httpd/conf/second.conf
echo 'PidFile /var/run/httpd-second.pid' >> /etc/httpd/conf/second.conf

systemctl start httpd@first
systemctl start httpd@second

ss -tnulp | grep httpd

