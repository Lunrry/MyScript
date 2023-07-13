#!/bin/sh
process()
{
install_date="zabbix_install_$(date +%Y-%m-%d_%H:%M:%S).log"

while :; do echo
    read -p "请输入Mysql数据库root密码: " Dataroot_Password
    read -p "请输入Mysql数据库zabbix密码: " Datazabbix_Password 
    [ -n "$Datazabbix_Password" ] && break
done
echo "#######################################################################"
echo "#                                                                     #"
echo "#                  正在关闭SElinux策略 请稍等~                        #"
echo "#                                                                     #"
echo "#######################################################################"
#临时关闭SElinux
setenforce 0
#永久关闭SElinux
sed -i "s/SELINUX=enforcing/SELINUX=disabled/" /etc/selinux/config
#配置Firewall策略 
echo "#######################################################################"
echo "#                                                                     #"
echo "#                  正在配置Firewall策略 请稍等~                       #"
echo "#                                                                     #"
echo "#######################################################################"
firewall-cmd --zone=public --add-port=80/tcp --permanent
firewall-cmd --zone=public --add-port=10050/tcp --permanent
firewall-cmd --zone=public --add-port=10051/tcp --permanent
firewall-cmd --reload
firewall-cmd --zone=public --list-ports
#放行TCP80、10050、10051端口

echo "#######################################################################"
echo "#                                                                     #"
echo "#                   正在编译Zabbix软件 请稍等~                        #"
echo "#                                                                     #"
echo "#######################################################################"

#去官网下载Zabbix：https://www.zabbix.com/download_sources
rpm -Uvh https://repo.zabbix.com/zabbix/5.0/rhel/7/x86_64/zabbix-release-5.0-1.el7.noarch.rpm
yum clean all
sed -ri 's/enabled=0/enabled=1/g' /etc/yum.repos.d/zabbix.repo
#安装Zabbix
yum -y install centos-release-scl
yum -y install zabbix-server-mysql zabbix-agent zabbix-web-mysql-scl zabbix-nginx-conf-scl
echo $?="Zabbix编译完成"
#安装Mariadb数据库
echo "#######################################################################"
echo "#                                                                     #"
echo "#                 正在安装Mariadb数据库 请稍等~                       #"
echo "#                                                                     #"
echo "#######################################################################"
yum install -y mariadb-server mariadb 
systemctl start mariadb
systemctl enable mariadb
#配置Mariadb数据库
echo "#######################################################################"
echo "#                                                                     #"
echo "#                   正在配置Mariadb数据库 请稍等~                     #"
echo "#                                                                     #"
echo "#######################################################################"
mysql_secure_installation << EOF

y
$Dataroot_Password
$Dataroot_Password
y
y
y
y
EOF

#创建zabbix数据库zabbix用户并配置权限
mysql -uroot -p$Dataroot_Password -e "create database zabbix character set utf8 collate utf8_bin;"
mysql -uroot -p$Dataroot_Password -e "create user zabbix@localhost identified by '$Datazabbix_Password';"
mysql -uroot -p$Dataroot_Password -e "grant all privileges on zabbix.* to zabbix@localhost;"

# zabbix数据库导入
zcat /usr/share/doc/zabbix-server-mysql*/create.sql.gz | mysql -uzabbix -p$Datazabbix_Password zabbix

echo "#######################################################################"
echo "#                                                                     #"
echo "#                   正在修改zabbix配置文件                             #"
echo "#                                                                     #"
echo "#######################################################################"
ip=$(hostname -I)
sed -ri "s/^# DBPassword=/DBPassword= $Datazabbix_Password/g" /etc/zabbix/zabbix_server.conf
sed -ri 's/^#        listen          80/listen          80/g' /etc/opt/rh/rh-nginx116/nginx/conf.d/zabbix.conf
sed -ri "s/^#        server_name     example.com/server_name    $ip/g" /etc/opt/rh/rh-nginx116/nginx/conf.d/zabbix.conf
sed -ri 's/listen.acl_users = apache/listen.acl_users = apache,nginx/' /etc/opt/rh/rh-php72/php-fpm.d/zabbix.conf
sed -ri 's/^; //g' /etc/opt/rh/rh-php72/php-fpm.d/zabbix.conf
sed -ri 's#Europe/Riga#Asia/Shanghai #g' /etc/opt/rh/rh-php72/php-fpm.d/zabbix.conf

sed -ri 's/^listen       80 default_server;/#listen       80 default_server;/g' /etc/opt/rh/rh-nginx116/nginx/nginx.conf
sed -ri 's/^listen       [::]:80 default_server;/#listen       [::]:80 default_server;/g' /etc/opt/rh/rh-nginx116/nginx/nginx.conf
sed -ri 's/^server_name  _;/#server_name  _;/g' /etc/opt/rh/rh-nginx116/nginx/nginx.conf
sed -ri 's/^root         /opt/rh/rh-nginx116/root/usr/share/nginx/html;/#root         /opt/rh/rh-nginx116/root/usr/share/nginx/html;/g' /etc/opt/rh/rh-nginx116/nginx/nginx.conf
sed -ri 's/^include      /etc/opt/rh/rh-nginx116/nginx/default.d/*.conf;/#include      /etc/opt/rh/rh-nginx116/nginx/default.d/*.conf;/g' /etc/opt/rh/rh-nginx116/nginx/nginx.conf
/opt/rh/rh-nginx116/root/usr/sbin/nginx
/opt/rh/rh-nginx116/root/usr/sbin/nginx -s reload

systemctl restart zabbix-server zabbix-agent rh-nginx116-nginx rh-php72-php-fpm
systemctl enable zabbix-server zabbix-agent rh-nginx116-nginx rh-php72-php-fpm
echo "--------------------------- 安装已完成 ---------------------------"
echo " 数据库名     :zabbix"
echo " 数据库用户名:密码 :root:$Dataroot_Password"
echo " 数据库用户名：密码 :zabbix:$Datazabbix_Password"
echo " 网站目录     : /usr/share/zabbix"
echo " Zabbix登录   ：http://$ip"
echo " 网站用户名   : Admin"
echo " 网站密码     : zabbix"
echo " 安装日志文件 :/var/log/"$install_date
echo "------------------------------------------------------------------"
echo "------------------------------------------------------------------"
}
LOGFILE=/var/log/"zabbix_install_$(date +%Y-%m-%d_%H:%M:%S).log"
touch $LOGFILE
tail -f $LOGFILE &
pid=$!
exec 3>&1
exec 4>&2
exec &>$LOGFILE
process
ret=$?
exec 1>&3 3>&-
exec 2>&4 4>&-

