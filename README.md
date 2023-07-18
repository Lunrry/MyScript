# MyScript

## mysql

| 脚本                   | 功能                                      |
| ---------------------- | ----------------------------------------- |
| reset_root_password.sh | mysql-8修改root用户密码                   |
| backup.sh              | mysql-8自动备份 - 配合cron使用 crontab -e |



## system

| 脚本                  | 功能                                                         |
| --------------------- | ------------------------------------------------------------ |
| system_info_colour.sh | CentOS5/6/7/RHEL5/6/7，查看基本信息（CPU，内存，磁盘，网络） |
| system_check.sh       | CentOS/RHEL 6/7 输出详细系统检查报告                         |

## docker

| 脚本              | 功能               |
| ----------------- | ------------------ |
| docker_install.sh | 安装指定版本docker |

## fastdfs

| 脚本            | 功能        |
| --------------- | ----------- |
| fdfs_install.sh | 安装fastdfs |

## ansible

| 运行命令                         | 功能                                      | 使用方法                                                     |
| -------------------------------- | ----------------------------------------- | ------------------------------------------------------------ |
| ansible-playbook zabbixagent.yml | 通过ansible向主机批量添加zabbix-agent程序 | 1. 上传zabbixagent文件夹到/etc/ansible/roles<br>2. 修改/etc/ansible/roles/zabbixagent/files/zabbix_agentd.conf中Server=和ServerActive=的值为zabbix-server主机ip<br>3. 上传 zabbixagent.yml文件至/etc/ansible<br/>4. 修改/etc/ansible/hosts文件<br/>5. 执行ansible-playbook zabbixagent.yml |
