#!/bin/bash
#Install / configure mysql as beackend db for the tasks application.
#Original scripts from Nutanix CALM early version used, modified for ansible deployment.
#Target is an aws ec2 instance
#$1 is the mysql database password, of the homestead database
#hardev@nutanix.com Aug'22

set -ex

#Insall packages, disable selinux and firewall then setup NTP
sudo yum install -y "http://repo.mysql.com/mysql-community-release-el7-5.noarch.rpm"
sudo yum update -y
sudo setenforce 0 || true
sudo sed -i 's/enforcing/disabled/g' /etc/selinux/config /etc/selinux/config
sudo systemctl stop firewalld || true
sudo systemctl disable firewalld || true
sudo yum install -y mysql-community-server.x86_64 unzip zip lvm2 lsof ntp
sudo ntpdate -u -s 0.pool.ntp.org 1.pool.ntp.org 2.pool.ntp.org 3.pool.ntp.org
sudo systemctl enable ntpd
sudo systemctl restart ntpd

#Set mySQL switches for renote access and future support for DB Service, start mySQL
sudo bash -c 'echo "[mysqld]" >> /etc/my.cnf'
sudo bash -c 'echo "bind-address = 0.0.0.0" >> /etc/my.cnf'
sudo bash -c 'echo "log-bin=mysql-bin.log" >> /etc/my.cnf'
sudo /bin/systemctl start mysqld
sudo /bin/systemctl enable mysqld

#Setup mySQL database and users, password for root and user homestead is the same and passed in via $1
mysql -u root<<-EOF
UPDATE mysql.user SET Password=PASSWORD('$1') WHERE User='root';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.db WHERE Db='test' OR Db='test\_%';
CREATE USER 'root'@'%' IDENTIFIED BY '$1'; 
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION;
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY '$1';
FLUSH PRIVILEGES;
CREATE DATABASE homestead;
GRANT ALL PRIVILEGES ON homestead.* TO 'homestead'@'%' IDENTIFIED BY '$1';
FLUSH PRIVILEGES;
EOF

#Throw in a restart of mySQL!
sudo /bin/systemctl restart mysqld
