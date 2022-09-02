#!/bin/bash
#Customize Task manager Application
#hardev@nutanix.com Aug'22
#Setup Nutanix background colors RGBs
   #0 NTNX Turq   rgb(78,178,221);
   #1 NTNX Orange rgb(242, 173, 56);
   #2 NTNX Blue   rgb(0, 53, 108;
   #3 NTNX Green  rgb(172, 209, 71);

colors=('rgb(172, 209, 71);' 'rgb(0, 53, 108);' 'rgb(242, 173, 56);' 'rgb(78,178,221);')
webserveri=$1 #Which webserver to customize
#make customizations to the php file
pubdir="/var/www/laravel/public"
phpdir="/var/www/laravel/resources/views/layouts"
phpfile="app.blade.php"
archpicfile="arch-ansible.jpg"
archpicsource="https://raw.githubusercontent.com/hardevsanghera/arch/master"
#Get external IP Aaddress to display on application web page
myip=$(curl -4 ifconfig.io)
#Change Background color
echo "Index Value is: $webserveri" > /tmp/cust.txt
echo "Array Value is: ${colors[$webserveri]}" >> /tmp/cust.txt
sed -i "s/\#005495\;/${colors[$webserveri]}/" "$phpdir/$phpfile"
#Change web page title
sed -i 's/Laravel Quickstart - Basic/Nutanix + Ansible Demonstration/' "$phpdir/$phpfile"
sleep 1
#Heading message and IP address of the targeted webserver
sed -i "s/Task Manager v12.0<\/h2>/<h2 style=\"color: white;\">Task Manager Managed+Deployed with Ansible+Nutanix<\/h2><h2 style=\"color: white;\">[webserver IP: $myip]<\/h2>XXXXXX/" "$phpdir/$phpfile"
sleep 1
sed -i "s/XXXXXX/<a href=\"{{URL::asset('$archpicfile')}}\">See Architecture<\/a>/" "$phpdir/$phpfile"
#Get jpg from github
cd $pubdir && curl -LJO $archpicsource/$archpicfile
sudo chmod 777 $archpicfile
sudo chown nginx:nginx $archpicfile
echo "====Done"
