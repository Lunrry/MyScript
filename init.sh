#!/bin/bash

pwd=$(pwd)
# 颜色参数，让脚本更好看
Green="\033[32m"
Font="\033[0m"
Red="\033[31m" 
# wget重试次数
wget_retry_number=${wget_retry_number:-"3"}

# root权限
if [[ $EUID -ne 0 ]]; then
                echo -e "${Red}你现在不是root权限，请使用sudo命令或者联系网站管理员${Font}"
                exit 1
        fi

        yum install -y wget whiptail
        cd /etc/yum.repos.d
                inspect_script_yum=$(whiptail --title "#是否yum换源#" --menu "#是否yum换源#" --ok-button 确认 --cancel-button 退出 20 65 13 \
                "0" "不换源" \
                "1" "阿里" \
                "2" "网易"\
                "3" "清华大学"\
                "4" "退出" 3>&1 1>&2 2>&3)
                EXITSTATUS_YUM=$?
                if [ $EXITSTATUS_YUM = 0 ]; then
                        case $inspect_script_yum in
                        0)
                                echo -e "${Green}您已选择不换源${Font}"
                                ;;
                        1)
                                mv Centos-Base.repo Centos-Base.repo.bak
                                wget -t {wget_retry_number} -O Centos-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo
                                yum clean all && yum makecache
                                ;;
                        2)
                                mv Centos-Base.repo Centos-Base.repo.bak
                                wget -t {wget_retry_number} -O Centos-Base.repo http://mirrors.163.com/.help/CentOS7-Base-163.repo
                                yum clean all && yum makecache
                                ;;
                        3)
                                sed -e 's|^mirrorlist=|#mirrorlist=|g' \
                                -e 's|^#baseurl=http://mirror.centos.org|baseurl=https://mirrors.tuna.tsinghua.edu.cn|g' \
                                -i.bak \
                                /etc/yum.repos.d/CentOS-*.repo
                                yum clean all && yum makecache
                                ;;
                        *)
                                echo -e "${Red}操作错误${Font}"
                                ;;
                        esac
                else
                        exit 0
                fi
sleep 1

echo "安装基本工具"
    yum install -y yum-utils device-mapper-persistent-data lvm2 tree git bash-completion.noarch \
         chrony lrzsz tar zip unzip gcc-c++ pcre pcre-devel zlib zlib-devel openssl openssl--devel
sleep 1

echo "同步时间服务器"
    systemctl enable chronyd --now
    sleep 1

echo "Linux最大进程数最大进程数量"
if [ $? -ne 0 ];then
    cat >> /etc/security/limits.d/20-nproc.conf << EOF
    * soft nproc unlimited
    * hard nproc unlimited
EOF
fi
sleep 1

echo "设置打开文件描述符的数量"
grep 'soft    nofile  65535' /etc/security/limits.conf > /dev/null 2>&1
if [ $? -ne 0 ];then
	echo '*    soft    nofile  65535' >> /etc/security/limits.conf
	echo '*    hard    nofile  65535' >> /etc/security/limits.conf
	echo '*    soft    nproc 65535' >> /etc/security/limits.conf
	echo '*    hard    nproc 65535' >> /etc/security/limits.conf
fi
cat /etc/security/limits.conf
sleep 1

echo "Linux系统所有进程共计可以打开的文件数量"
cat >> /etc/sysctl.conf << EOF
fs.file-max = 65535
EOF


yum update -y


