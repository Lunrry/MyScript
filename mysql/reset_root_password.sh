#!/bin/bash

PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

#检查是否为root用户
if [ $(id -u) != "0" ]; then
    printf "Error: 该脚本必须在root用户下运行\n"
    exit 1
fi

read -p "请输入mysql可执行文件地址，使用which mysql获取，默认为：/data/mysql/bin/mysql：" mysql
if [[ "$mysql" == "" ]]
then
    mysql='/data/mysql/bin/mysql'
    echo 默认路径：/data/mysql/bin/mysql
fi

echo "请输入新密码："
read -s new_password
echo "请等待几秒，正在修改密码"

systemctl stop mysql
if ! grep -q "skip-grant-tables" /etc/my.cnf; then
    sed -i '/\[mysqld\]/a skip-grant-tables' /etc/my.cnf
fi

sed -i '/^#skip-grant-tables/s/^#//' /etc/my.cnf

if ! grep -q "default_authentication_plugin = mysql_native_password" /etc/my.cnf; then
sed -i '/\[mysqld\]/a default_authentication_plugin = mysql_native_password' /etc/my.cnf
fi
systemctl start mysql

${mysql} -u root mysql << EOF
use mysql;
update user set authentication_string='' where user='root';
flush privileges;
quit
EOF

sed -i '/skip-grant-tables/s/^/#/' /etc/my.cnf
${mysql} -u root mysql << EOF
use mysql;
ALTER USER 'root'@'%' IDENTIFIED BY '$new_password';
flush privileges;
quit
EOF
if [ $? -ne 0 ]; then
    exit 1
else
    echo "密码修改成功"
fi
