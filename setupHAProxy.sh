#!/bin/bash
#Install / configure HAProxy (load balancer) for a 3-tier app.
#Original scripts from Nutanix CALM early ersion sued, modified for ansible deployment.
#Target is an aws ec2 instance
#$1 is the IP of the targeted webserver(s)
#hardev@nutanix.com Auh'22

#set -ex

sudo yum update -y
sudo yum install -y haproxy
sudo setenforce 0 ||
sudo sed -i 's/enforcing/disabled/g' /etc/selinux/config /etc/selinux/config
sudo systemctl stop firewalld || true
sudo systemctl disable firewalld || true

echo "global
 log 127.0.0.1 local0
 log 127.0.0.1 local1 notice
 maxconn 4096
 quiet
 user haproxy
 group haproxy
defaults
 log global
 mode http
 retries 3
 timeout client 50s
 timeout connect 5s
 timeout server 50s
 option dontlognull
 option httplog
 option redispatch
 balance roundrobin
# Set up application listeners here.
listen admin
 bind 127.0.0.1:22002
 mode http
 stats uri /
frontend http
 maxconn 2000
 bind 0.0.0.0:80
 default_backend servers-http
backend servers-http" | sudo tee /etc/haproxy/haproxy.cfg

hosts=$(echo $1 | tr "," "\n") #$1 is the IP address of the webserver(s) to point to - starting with a single webserver - will mod to support two.
port=80

for host in $hosts
  do echo " server host-${host} ${host}:${port} weight 1 maxconn 100 check" | sudo tee -a /etc/haproxy/haproxy.cfg
done

sudo systemctl daemon-reload
sudo systemctl enable haproxy
sudo systemctl restart haproxy