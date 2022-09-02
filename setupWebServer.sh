#!/bin/bash
#Install / configure nginx webserver for a 3-tier app.
#Original scripts from Nutanix CALM early version used, modified for ansible deployment and use of ssh tunnel
#Target is an aws ec2 instance
#$1 is the mysql database password
#hardev@nutanix.com Aug'22
set -ex

#Target is an ec2 instance
sudo yum update -y
sudo amazon-linux-extras install epel -y
sudo yum clean metadata

sudo setenforce 0 || true
sudo sed -i 's/enforcing/disabled/g' /etc/selinux/config /etc/selinux/config
sudo systemctl stop firewalld || true
sudo systemctl disable firewalld || true

#Get the basic task application, uses the laravel framework
#Need "older" versions of the packages - good enough for demo purposes
sudo rpm -Uvh https://mirror.webtatic.com/yum/el7/webtatic-release.rpm
sudo yum install -y nginx php56w-fpm php56w-cli php56w-mcrypt php56w-mysql php56w-mbstring php56w-dom git unzip

sudo mkdir -p /var/www/laravel
#Laravel cobfig follows
echo "server {
 listen 80 default_server;
 listen [::]:80 default_server ipv6only=on;
root /var/www/laravel/public/;
 index index.php index.html index.htm;
location / {
 try_files \$uri \$uri/ /index.php?\$query_string;
 }
 # pass the PHP scripts to FastCGI server listening on /var/run/php5-fpm.sock
 location ~ \.php$ {
 try_files \$uri /index.php =404;
 fastcgi_split_path_info ^(.+\.php)(/.+)\$;
 fastcgi_pass 127.0.0.1:9000;
 fastcgi_index index.php;
 fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
 include fastcgi_params;
 }
}" | sudo tee /etc/nginx/conf.d/laravel.conf
sudo sed -i 's/80 default_server/80/g' /etc/nginx/nginx.conf
if `grep "cgi.fix_pathinfo" /etc/php.ini` ; then
 sudo sed -i 's/cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/' /etc/php.ini
else
 sudo sed -i 's/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/' /etc/php.ini
fi

sudo systemctl enable php-fpm
sudo systemctl enable nginx
sudo systemctl restart php-fpm
sudo systemctl restart nginx

if [ ! -e /usr/local/bin/composer ]
then
 curl -sS https://getcomposer.org/installer | php
 sudo mv composer.phar /usr/local/bin/composer
 sudo chmod +x /usr/local/bin/composer
fi

sudo git clone https://github.com/ideadevice/quickstart-basic.git /var/www/laravel
sudo sed -i 's/DB_HOST=.*/DB_HOST=127.0.0.1/' /var/www/laravel/.env
echo 'DB_PORT=5555' | sudo tee -a /var/www/laravel/.env
sudo su - -c "cd /var/www/laravel; composer install"

#change localhost to 127.0.0.1
sudo sed -i 's/localhost/127\.0\.0\.1/' /var/www/laravel/config/database.php

#change defaults to homestead - will do two occurences with the first sed
sudo sed -i 's/forge/homestead/' /var/www/laravel/config/database.php

#Add the password and the port
#port and password - change ecveryref - probs overkill as the .env file wins!
sudo sed -i "s/'DB_PASSWORD'\, '')\,/'DB_PASSWORD'\, '$1')\, 'port' \=\> env('DB_PORT'\, '5555')\,/"  /var/www/laravel/config/database.php
sudo sed -i "s/secret/$1/"  /var/www/laravel/.env

#Is the ssh tunnel listening on port 5555?
#Wait until the ssh tunnel (and therefore the link to the backend mysql dtabase) is up
#This webserver will talk to port 3306 on the mysql server and get there by using port 5555 on itself - simples!
tunupandrunning="DOWN"
while [[ $tunupandrunning == "DOWN" ]]
 do
   echo "==Tunnel is DOWN"
   sleep 10
   (netstat -tunl | grep '127.0.0.1:5555') && tunupandrunning="UP"
 done
 echo "====Tunnel is UP"

#Migrate database only if this is the first webserver
#In laravel migrate means setup the database tables in this case
if [ $2 == "0" ]; then
 sudo su - -c "cd /var/www/laravel; php artisan migrate"
fi

sudo chown -R nginx:nginx /var/www/laravel
sudo chmod -R 777 /var/www/laravel/
sudo systemctl restart nginx