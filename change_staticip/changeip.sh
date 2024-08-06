#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

echo -e "${RED}======================================================${NC}"
echo -e "${RED}===============此命令会修改网卡静态ip地址=============${NC}"
echo -e "${RED}===================仅适用当前机器=====================${NC}"
echo -e "${RED}======================================================${NC}"
echo "当前网卡信息为："
cat /etc/sysconfig/network-scripts/ifcfg-ens32

sed -i 's/BOOTPROTO="none"/BOOTPROTO="static"/' /etc/sysconfig/network-scripts/ifcfg-ens32
sed -i "s/IPADDR=\"192.168.0.3\"/IPADDR=\"192.168.0.${1}\"/" /etc/sysconfig/network-scripts/ifcfg-ens32


sleep 3
service network restart
