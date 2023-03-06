#!/bin/bash
yum update -y
yum clean all
mkdir -pm 700 /home/vagrant/.ssh
curl -sL https://raw.githubusercontent.com/mitchellh/vagrant/master/keys/vagrant.pub -o /home/vagrant/.ssh/authorized_keys
chmod 0600 /home/vagrant/.ssh/authorized_keys
chown -R vagrant:vagrant /home/vagrant/.ssh
rm -rf /tmp/*
rm  -f /var/log/wtmp /var/log/btmp
rm -rf /var/cache/* /usr/share/doc/*
rm -rf /var/cache/yum
rm -rf /vagrant/home/*.iso
rm  -f ~/.bash_history
echo 'vagrant ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/vagrant
history -c
rm -rf /run/log/journal/*
sync
grub2-set-default 0
echo "###   Hi from second stage" >> /boot/grub2/grub.cfg