#!/bin/bash
 
# 脚本存放位置即为备份文件存放位置

PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/home/data/mysql/bin:/data/mysql/bin
# 定义属性
MYSQL_HOST="127.0.0.1"
 
MYSQL_PORT="3306"
 
MYSQL_USER="root"
 
MYSQL_PASSWORD="123456"
 
BACKUP=$(cd `dirname $0`;pwd)
echo "$BACKUP"
 
DATETIME=$(date +%Y_%m_%d_%H_%M_%S)
echo "$DATETIME"

mysqldir=$(which mysql)
#echo "$mysqldir"

mysqldumpdir=$(which mysqldump)
#echo "$mysqldumpdir"
 
touch $BACKUP/backuplog.log
# 打印日志
function log_correct () {
    USER=$(whoami)
    echo "${DATETIME} ${USER} execute $0 [INFO] $@ " >> "$BACKUP/backuplog.log" 
}
 
log_correct "开始执行 Mysql 备份任务"
 
# 自动获得所有的数据库
DATABASES=`${mysqldir} -h${MYSQL_HOST} -P${MYSQL_PORT} -u${MYSQL_USER} -p${MYSQL_PASSWORD} -e "SHOW DATABASES;"`
# 创建备份目录
mkdir -p "${BACKUP}/$DATETIME"
 
for db in $DATABASES; do
    # 排除表头和一些无需备份的数据库
    if [[ "$db" != "Database" ]] && [[ "$db" != "information_schema" ]] && [[ "$db" != "performance_schema" ]] && [[ "$db" != "mysql" ]] && [[ "$db" != "sys" ]] ; then
        # 备份操作
        log_correct "备份: 【$db】"
        ${mysqldump} --ignore-table=$db\.TS_S_OperationLog -h${MYSQL_HOST} -P${MYSQL_PORT} -u${MYSQL_USER} -p${MYSQL_PASSWORD} --databases $db > ${BACKUP}/$DATETIME/$db.sql
        log_correct "数据库【$db】已备份到：${BACKUP}/$DATETIME/$db.tar.gz 下"
	cd $BACKUP/$DATETIME
	tar -czvf $db.tar.gz $db.sql
	rm -rf *.sql
    fi
done
 
# 删除10天前的备份文件
find $BACKUP -type d -mtime +10 -exec rm -rf {} \;
 
log_correct "完成 Mysql 备份任务"

log_correct "已删除10天前备份数据"