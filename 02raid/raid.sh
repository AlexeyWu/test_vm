#!/bin/bash
echo 'vagrant ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/vagrant
sudo mdadm --create --verbose /dev/md6 -l 6 -n 5 /dev/sd{b,c,d,e,f}
sudo echo "DEVICE partitions" > /etc/mdadm/mdadm.conf
sudo mdadm --detail --scan --verbose | awk '/ARRAY/ {print}' >> /etc/mdadm/mdadm.conf
sudo parted -s /dev/md6 mklabel gpt
sudo parted /dev/md6 mkpart primary ext4 0% 20%
sudo parted /dev/md6 mkpart primary ext4 20% 40%
sudo parted /dev/md6 mkpart primary ext4 40% 60%
sudo parted /dev/md6 mkpart primary ext4 60% 80%
sudo parted /dev/md6 mkpart primary ext4 80% 100%
for i in $(seq 1 5); do sudo mkfs.ext4 /dev/md6p$i; done
sudo mkdir -p /raid/part{1,2,3,4,5}
for i in $(seq 1 5); do sudo mount /dev/md6p$i /raid/part$i; done
sudo su -c "echo '/dev/md6p1 /raid/part1 ext4 defaults 0 0' >> /etc/fstab"
sudo su -c "echo '/dev/md6p2 /raid/part2 ext4 defaults 0 0' >> /etc/fstab"
sudo su -c "echo '/dev/md6p3 /raid/part3 ext4 defaults 0 0' >> /etc/fstab"
sudo su -c "echo '/dev/md6p4 /raid/part4 ext4 defaults 0 0' >> /etc/fstab"
sudo su -c "echo '/dev/md6p5 /raid/part5 ext4 defaults 0 0' >> /etc/fstab"
