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

printf "${BLUE}"
cat << EOF

###################################################################################
# install FastDFS 脚本
# FastDFS 会被install到 /data/fdfs 路径。
# @system: 适用于 CentOS
# @author: Zhang Peng / Tao Zhi
###################################################################################

EOF
printf "${RESET}"

printf "${GREEN}>>>>>>>> install fastdfs begin.${RESET}\n"


command -v yum > /dev/null 2>&1 || {
	printf "${RED}Require yum but it's not installed.${RESET}\n";
	exit 1;
}

if [[ $# -lt 1 ]] || [[ $# -lt 2 ]]; then
	printf "${PURPLE}[Hint]\n"
	printf "\t sh fastdfs-install.sh [path]\n"
	printf "\t Example: sh fastdfs-install.sh /opt/fastdfs\n"
	printf "${RESET}\n"
fi

path=/data/fdfs
if [[ -n $1 ]]; then
	path=$1
fi


nginx_version=1.22.0
nginx_path=/data/nginx
CPU_NUM=`cat /proc/cpuinfo | grep processor | wc -l`
mkdir -p $nginx_path/cache/nginx/client_temp


printf "${GREEN}>>>>>>>> install required libs.${RESET}\n\n"
yum install -y git gcc gcc-c++ make automake autoconf libtool pcre pcre-devel zlib zlib-devel openssl-devel wget vim unzip openssl perl-devel perl glib2-devel bzip2-devel gzip-devel libxslt* libxml2* gd-devel GeoIP-devel lua* luajit-devel zip

# download and decompression
mkdir -p ${path}
path=/data/fdfs
curl -o ${path}/libfastcommon-1.0.43.tar.gz https://ghproxy.com/https://raw.githubusercontent.com/Lunrry/Software_installation/main/file/fastdfs/libfastcommon-1.0.43.tar.gz
if [[ ! -f ${path}/libfastcommon-1.0.43.tar.gz ]]; then
	printf "${RED}[Error]install libfastcommon failed，exit. ${RESET}\n"
	exit 1
fi
tar xf ${path}/libfastcommon-1.0.43.tar.gz -C ${path}
cd ${path}/libfastcommon-1.0.43
chmod +x -R ${path}/libfastcommon-1.0.43/*.sh
./make.sh && ./make.sh install


printf "${GREEN}>>>>>>>>> install fastdfs${RESET}"
curl -o ${path}/fastdfs-6.06.tar.gz https://ghproxy.com/https://raw.githubusercontent.com/Lunrry/Software_installation/main/file/fastdfs/fastdfs-6.06.tar.gz
if [[ ! -f ${path}/fastdfs-6.06.tar.gz ]]; then
	printf "${RED}>>>>>>>>> install fastdfs failed，exit. ${RESET}\n"
fi
tar xf ${path}/fastdfs-6.06.tar.gz -C ${path}
cd ${path}/fastdfs-6.06
chmod +x -R ${path}/fastdfs-6.06/*.sh
./make.sh && ./make.sh install


printf "${GREEN}>>>>>>>>> install fastdfs-nginx-module${RESET}\n"
curl -o ${path}/fastdfs-nginx-module-1.22.tar.gz https://ghproxy.com/https://raw.githubusercontent.com/Lunrry/Software_installation/main/file/fastdfs/fastdfs-nginx-module-1.22.tar.gz
if [[ ! -f ${path}/fastdfs-nginx-module-1.22.tar.gz ]]; then
	printf "${RED}>>>>>>>>> install fastdfs-nginx-module failed，exit. ${RESET}\n"
fi
tar xf ${path}/fastdfs-nginx-module-1.22.tar.gz -C ${path}


printf "${GREEN}>>>>>>>>> install nginx${RESET}"
mkdir -p ${nginx_path}
curl -o ${nginx_path}/nginx-${nginx_version}.tar.gz http://nginx.org/download/nginx-${nginx_version}.tar.gz
tar zxf ${nginx_path}/nginx-${nginx_version}.tar.gz -C ${nginx_path}
cd ${nginx_path}/nginx-${nginx_version}
./configure --prefix=/etc/nginx --sbin-path=/usr/sbin/nginx \
                --modules-path=/usr/lib/nginx/modules --conf-path=/etc/nginx/nginx.conf \
                --error-log-path=$nginx_path/log/nginx/error.log --http-log-path=$nginx_path/log/nginx/access.log \
                --pid-path=$nginx_path/run/nginx.pid --lock-path=$nginx_path/run/nginx.lock \
                --http-client-body-temp-path=$nginx_path/cache/nginx/client_temp \
                --http-proxy-temp-path=$nginx_path/cache/nginx/proxy_temp \
                --http-fastcgi-temp-path=$nginx_path/cache/nginx/fastcgi_temp \
                --http-uwsgi-temp-path=$nginx_path/cache/nginx/uwsgi_temp \
                --http-scgi-temp-path=$nginx_path/cache/nginx/scgi_temp \
                --user=nginx --group=nginx --with-http_ssl_module \
                --with-http_realip_module --with-http_addition_module \
                --with-http_sub_module --with-http_dav_module --with-http_flv_module \
                --with-http_mp4_module --with-http_gunzip_module --with-http_gzip_static_module \
                --with-http_random_index_module --with-http_secure_link_module --with-http_stub_status_module \
                --with-http_auth_request_module --with-http_xslt_module=dynamic --with-http_image_filter_module=dynamic \
                --with-http_geoip_module=dynamic --with-threads --with-stream --with-stream_ssl_module \
                --with-stream_ssl_preread_module --with-stream_realip_module --with-stream_geoip_module=dynamic \
                --with-http_slice_module --with-mail --with-mail_ssl_module --with-compat --with-file-aio --with-http_v2_module \
				--add-module=${path}/fastdfs-nginx-module-1.22/src/
make -j$CPU_NUM && make install
/usr/sbin/useradd -c "nginx user" -s /bin/false -r -d /var/lib/nginx nginx

printf "${GREEN}>>>>>>>>> fastdfs 配置文件准备${RESET}\n"
# 配置修改参考：https://github.com/happyfish100/fastdfs/wiki

chmod +x /etc/rc.d/rc.local
mkdir -p /etc/fdfs
cp ${path}/fastdfs-6.06/conf/http.conf /etc/fdfs/ #供nginx访问使用
cp ${path}/fastdfs-6.06/conf/mime.types /etc/fdfs/ #供nginx访问使用
cp ${path}/fastdfs-nginx-module-1.22/src/mod_fastdfs.conf /etc/fdfs

TRACJER_DIR=/data/fastdfs/tracker
storage_data=/data/fastdfs/storage
ip=$(ip addr | awk '/^[0-9]+: / {}; /inet.*global/ {print gensub(/(.*)\/(.*)/, "\\1", "g", $2)}')
mkdir -p $TRACJER_DIR
mkdir -p $storage_data

#修改配置
printf "${GREEN} - 修改 tracker.conf 配置${RESET}\n"
cp -r /etc/fdfs/tracker.conf.sample /etc/fdfs/tracker.conf
sed -i "s/base_path/#base_path/g" /etc/fdfs/tracker.conf
sed -i "s/http.server_port/#http.server_port/g" /etc/fdfs/tracker.conf
echo 'base_path = '$TRACJER_DIR >> /etc/fdfs/tracker.conf
echo 'http.server_port = 6666' >> /etc/fdfs/tracker.conf


printf "${GREEN} - 修改 storage.conf 配置${RESET}\n"
cp -r /etc/fdfs/storage.conf.sample /etc/fdfs/storage.conf
#修改配置
sed -i "s/group_name/#group_name/g" /etc/fdfs/storage.conf
sed -i "s/port = 23000/#port = 23000/g" /etc/fdfs/storage.conf
sed -i "s/base_path =/#base_path =/g" /etc/fdfs/storage.conf
sed -i "s/store_path0 =/#store_path0 =/g" /etc/fdfs/storage.conf
sed -i "s/tracker_server =/#tracker_server =/g" /etc/fdfs/storage.conf
echo 'group_name = 'group1 >> /etc/fdfs/storage.conf
echo 'port = '2330 >> /etc/fdfs/storage.conf
echo 'base_path = '$storage_data >> /etc/fdfs/storage.conf
echo 'store_path0 = '$storage_data >> /etc/fdfs/storage.conf
echo 'tracker_server = '$ip':22122' >> /etc/fdfs/storage.conf


wget -N https://gitee.com/turnon/linux-tutorial/raw/master/codes/linux/soft/config/fastdfs/client.conf -O /etc/fdfs/client.conf
printf "${GREEN} - 修改 client.conf 配置${RESET}\n"
sed -i "s#^base_path=.*#base_path=${storage_data}#g" /etc/fdfs/client.conf
sed -i "s#^tracker_server=.*#tracker_server=${ip}:22122#g" /etc/fdfs/client.conf
sed -i "s#^base_path=.*#base_path=${storage_data}#g" /etc/fdfs/client.conf
sed -i "s#^tracker_server=.*#tracker_server=${ip}:22122#g" /etc/fdfs/client.conf


printf "${GREEN} - 修改 mod_fastdfs.conf 配置${RESET}\n"
sed -i "s#^url_have_group_name=.*#url_have_group_name=true#g" /etc/fdfs/mod_fastdfs.conf
sed -i "s#^tracker_server=.*#tracker_server=${ip}:22122#g" /etc/fdfs/mod_fastdfs.conf
sed -i "s#^store_path0=.*#store_path0=${storage_data}#g" /etc/fdfs/mod_fastdfs.conf


# printf "${GREEN} - 修改 nginx.conf 配置${RESET}\n"
# mkdir -p /etc/nginx/conf/conf
# wget -N https://gitee.com/turnon/linux-tutorial/raw/master/codes/linux/soft/config/nginx/nginx.conf -O /etc/nginx/conf/nginx.conf
# wget -N https://gitee.com/turnon/linux-tutorial/raw/master/codes/linux/soft/config/nginx/conf/fdfs.conf -O /etc/nginx/conf/conf/fdfs.conf


printf "${GREEN}>>>>>>>>> 启动 fastdfs ${RESET}\n"
chmod +x /etc/init.d/fdfs_trackerd
/etc/init.d/fdfs_trackerd start #启动tracker服务
#/etc/init.d/fdfs_trackerd restart #重启动tracker服务
#/etc/init.d/fdfs_trackerd stop #停止tracker服务
chkconfig fdfs_trackerd on #自启动tracker服务


chmod +x /etc/init.d/fdfs_storaged
/etc/init.d/fdfs_storaged start #启动storage服务
#/etc/init.d/fdfs_storaged restart #重动storage服务
#/etc/init.d/fdfs_storaged stop #停止动storage服务
chkconfig fdfs_storaged on #自启动storage服务


# wget -N https://gitee.com/turnon/linux-tutorial/raw/master/codes/linux/soft/config/nginx/nginx.service -O /usr/lib/systemd/system/nginx.service
# chmod +x /usr/lib/systemd/system/nginx.service
# #设置nginx.service为系统服务
# systemctl enable nginx.service
# ##通过系统服务操作nginx
# systemctl start nginx.service
# #systemctl reload nginx.service
# #systemctl restart nginx.service
# #systemctl stop nginx.service

# printf ">>>>>>>>> add fastdfs port"
# firewall-cmd --zone=public --add-port=6666/tcp --permanent
# firewall-cmd --zone=public --add-port=22122/tcp --permanent
# firewall-cmd --reload

printf "${GREEN}<<<<<<<< install fastdfs end.${RESET}\n"
#touch test.txt
#result=`fdfs_upload_file /etc/fdfs/client.conf test.txt`
#echo ${result}
#rm -f test.txt