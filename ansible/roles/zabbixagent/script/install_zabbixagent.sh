#!/bin/bash

rpm -Uvh https://repo.zabbix.com/zabbix/5.0/rhel/7/x86_64/zabbix-release-5.0-1.el7.noarch.rpm
yum install -y zabbix-agent

ip_addr=`ip a | grep inet | grep -v '127' | grep -v 'inet6' | awk '{print $2}' | grep '/24' | awk -F '/' '{print $1}'`
hostnamectl set-hostname "agent${ip_addr}"


firewall-cmd --zone=public --add-port=10050/tcp --permanent
firewall-cmd --reload