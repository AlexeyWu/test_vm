#!/bin/bash
sudo -i
#ставим нужные компоненты
#cd /etc/yum.repos.d/
#sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-*
#sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-*
#yum update -y

sudo yum install -y redhat-lsb-core wget rpmdevtools rpm-build createrepo yum-utils gcc
wget https://nginx.org/packages/centos/8/SRPMS/nginx-1.20.2-1.el8.ngx.src.rpm
#wget https://nginx.org/packages/centos/7/SRPMS/nginx-1.14.1-1.el7_4.ngx.src.rpm
rpm -i nginx-1.*
wget https://github.com/openssl/openssl/archive/refs/heads/OpenSSL_1_1_1-stable.zip
unzip OpenSSL_1_1_1-stable.zip
#поставим все зависимости
sudo yum-builddep -y rpmbuild/SPECS/nginx.spec
#copy nginx.spec to rpmbuild/SPECS/nginx.spec
cp nginx.spec rpmbuild/SPECS/nginx.spec
#сборка RPM пакета:
rpmbuild -bb rpmbuild/SPECS/nginx.spec
#Убеждаемся что пакеты созданы
ll rpmbuild/RPMS/x86_64/
#установливаем наш пакет
yum localinstall -y rpmbuild/RPMS/x86_64/nginx-1.14.1-1.el7_4.ngx.x86_64.rpm
systemctl start nginx
systemctl status nginx
#Далее создаем репозиторий
mkdir /usr/share/nginx/html/repo
cp rpmbuild/RPMS/x86_64/nginx-1.14.1-1.el7_4.ngx.x86_64.rpm /usr/share/nginx/html/repo/
wget https://downloads.percona.com/downloads/percona-distribution-mysql-ps/percona-distribution-mysql-ps-8.0.28/binary/redhat/8/x86_64/percona-orchestrator-3.2.6-2.el8.x86_64.rpm -O /usr/share/nginx/html/repo/percona-orchestrator-3.2.6-2.el8.x86_64.rpm
createrepo /usr/share/nginx/html/repo/
sed -n 'H;${x;s/^\n//;s/index .*$/autoindex on;\n&/;p;}' /etc/nginx/conf.d/default.conf
#perl -i -lpe 'print "autoindex on;" if $. == lineNumber' /etc/nginx/conf.d/default.conf
nginx -t
nginx -s reload
curl -a http://localhost/repo/
cat >> /etc/yum.repos.d/otus.repo << EOF
[otus]
name=otus-linux
baseurl=http://localhost/repo
gpgcheck=0
enabled=1
EOF
yum repolist enabled | grep otus
yum list | grep otus
yum install percona-orchestrator.x86_64 -y



#sudo yum install -y nfs-utils 
#sudo systemctl enable firewalld --now 
#sudo systemctl status firewalld 
#sudo echo '192.168.50.10:/srv/share/ /mnt nfs vers=3,proto=udp,x-systemd.automount 0 0' >> /etc/fstab
#sudo systemctl daemon-reload 
#sudo systemctl restart remote-fs.target 
#sudo touch /mnt/upload/client_file