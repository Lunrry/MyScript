#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

echo -e "${RED}======================================================${NC}"
echo -e "${RED}====此命令会修改网卡静态ip地址并重启，使用前请知晓====${NC}"
echo -e "${RED}===================仅适用当前机器=====================${NC}"
echo -e "${RED}======================================================${NC}"
echo "当前网卡信息为："
cat /etc/sysconfig/network-scripts/ifcfg-ens33
echo -e "${GREEN}输入主机标识号:${NC}"
read input
Host="$input"

sed -i 's/BOOTPROTO="none"/BOOTPROTO="static"/' /etc/sysconfig/network-scripts/ifcfg-ens33
sed -i "s/IPADDR=\"192.168.0.3\"/IPADDR=\"192.168.0.${Host}\"/" /etc/sysconfig/network-scripts/ifcfg-ens33

#service network restart
reboot
