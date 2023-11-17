#!/bin/bash

echo "----------------------"
echo "请选择要执行的命令："
echo "1. centos初始化配置"
echo "2. 安装fdfs-6.06（一般位于DB服务器）"
echo "3. 安装nginx-1.22.0（web服务器）"
echo "4. 安装nginx+fdfs，两者位于同一台机器"
echo "5. 安装nano-7.2编辑器"
echo "6. 安装docker"
echo "7. 安装k8s（自动安装适配版本docker）"
echo "8. 安装zabbix-5.0LTS"
echo "----------------------"

read choice

case $choice in
    1)
    echo "1. centos初始化配置"
    wget http://www.lunrry.top:99/p/qWBKhDJUto/init.sh && chmod +x init.sh && ./init.sh
;;
    2)
    echo "2. 安装fdfs-6.06（一般位于DB服务器）" 
    wget http://www.lunrry.top:99/p/h7RX4agM7k/install_fdfs.sh && chmod +x install_fdfs.sh && ./install_fdfs.sh
;;
    3)
    echo "3. 安装nginx-1.22.0（web服务器）"
    wget http://www.lunrry.top:99/p/IyEfzowg3q/nginx_install.sh && chmod +x nginx_install.sh && ./nginx_install.sh
    ;;
4)
    echo "4. 安装nginx+fdfs，两者位于同一台机器"
    wget http://www.lunrry.top:99/p/2O6ZjaqOvL/install_ngx_fdfs.sh && chmod +x install_ngx_fdfs.sh && ./install_ngx_fdfs.sh
;;
5)
    echo "5. 安装nano-7.2编辑器"
    wget http://www.lunrry.top:99/p/cbwpRZoCF8/install.sh && chmod +x install.sh && ./install.sh
;;
6)
    echo "6. 安装docker"
    wget http://www.lunrry.top:99/p/5RBqTgLPlI/docker_install.sh && chmod +x docker_install.sh && ./docker_install.sh
;;
7)
    echo "7. 安装k8s（自动安装适配版本docker）"
    wget http://www.lunrry.top:99/p/xSUEe3hsux/k8s_install.sh && chmod +x k8s_install.sh && ./k8s_install.sh
;;
8)
    echo "8. 安装zabbix-5.0LTS"
    wget http://www.lunrry.top:99/p/Aa5vSsbzbM/zabbix_install.sh && chmod +x zabbix_install.sh && ./zabbix_install.sh
;;
*)
    echo "无效选择"
;;
esac
