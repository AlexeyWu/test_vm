#!/bin/bash
#install zfs repo
echo sudo -i
#yum install -y http://zfsonlinux.org/epel/zfs-release-2-2$(rpm --eval "%{distr}").noarch.rpm
yum install -y http://download.zfsonlinux.org/epel/zfs-release.el7_8.noarch.rpm
#import gpg key 
rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-zfsonlinux
#install DKMS style packages for correct work ZFS
yum install -y epel-release kernel-devel zfs
#change ZFS repo
yum-config-manager --disable zfs
yum-config-manager --enable zfs-kmod
yum -y install zfs
#Add kernel module zfs
echo sudo modprobe zfs
#install wget
yum install -y wget
reboot