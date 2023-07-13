#!/usr/bin/env bash

###################################################################################
# 控制台颜色
BLACK="\033[1;30m"
RED="\033[1;31m"
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
BLUE="\033[1;34m"
PURPLE="\033[1;35m"
CYAN="\033[1;36m"
RESET="$(tput sgr0)"
###################################################################################

printf "${RESET}"

printf "${GREEN}>>>>>>>> install docker begin.${RESET}\n"
# uninstall old version docker
sudo yum list installed | grep docker
yum -y remove docker-ce.x86_64
sudo yum remove docker \
                  docker-client \
                  docker-client-latest \
                  docker-common \
                  docker-latest \
                  docker-latest-logrotate \
                  docker-logrotate \
                  docker-engine

# install required libs
sudo yum install -y yum-utils device-mapper-persistent-data lvm2
# add docker yum repo
sudo yum-config-manager --add-repo http://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
sudo yum makecache fast
# install docker
yum list docker-ce --showduplicates | sort -r
echo "版本号为：第一个冒号（:）一直到第一个连字符，如19.03.4"
read -p "请输入想要安装的docker版本: " docker_v
if [ -z "$docker_v" ]; then
  defaultInput="19.03.4"
  docker_v="$defaultInput"
fi
sudo yum install -y docker-ce-${docker_v} docker-ce-cli-${docker_v} containerd.io
sudo systemctl start docker
docker version
printf "${GREEN}<<<<<<<< install docker end.${RESET}\n"

printf "${GREEN}>>>>>>>> replace chinese docker mirror registry${RESET}\n"
if [[ -f "/etc/docker/daemon.json" ]]; then
    mv /etc/docker/daemon.json /etc/docker/daemon.json.bak
else
    mkdir -p /etc/docker
fi
touch /etc/docker/daemon.json
cat >> /etc/docker/daemon.json << EOF
{
  "registry-mirrors": ["https://hub-mirror.c.163.com"]
}
EOF
systemctl daemon-reload
systemctl restart docker
