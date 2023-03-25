#!/bin/bash
sudo yum install -y nfs-utils 
sudo systemctl enable firewalld --now 
sudo systemctl status firewalld 
sudo echo '192.168.50.10:/srv/share/ /mnt nfs vers=3,proto=udp,x-systemd.automount 0 0' >> /etc/fstab
sudo systemctl daemon-reload 
sudo systemctl restart remote-fs.target 
sudo touch /mnt/upload/client_file