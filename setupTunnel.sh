#!/bin/bash
#Setup reverse ssh tunnel to link aws webservers to the backend database server.
#This is a simple way to link the tiers - no need for a site2site VPN.
#Target is an aws ec2 instance
#$1 is the IP of the targeted webserver(s)
#hardev@nutanix.com Aug'22

#set -ex
sudo yum install -y sshpass

webserver=$2
echo "====webserver: $webserver"
sleep 30

IFS=',' 
read -a webs <<<"$webserver"
len=${#webs[@]}; echo "len: $len"
for (( i=0; i<$len; i++ )) 
    do
      currentweb=${webs[$i]}
      echo "Start tunnel for $currentweb"
      echo "====About to nohup"
      ( ( nohup sshpass -p $1 ssh -o StrictHostKeyChecking=no -R 5555:127.0.0.1:3306 -N webadmin@$currentweb </dev/null >/dev/null 2>&1 ) & ) 
      echo "====Done nohup"
    done
echo "====show jobs"
jobs
echo "====show processes"
ps -aux | grep webadmin
echo "====Done"