#!/bin/bash


CPU_NUM=`cat /proc/cpuinfo | grep processor | wc -l`
IP_ADDR=`ip a | grep inet | grep -v '127' | grep -v 'inet6' | awk '{print $2}' | grep '/24' | awk -F '/' '{print $1}'`

# 默认安装位置
default_install_dir="/home/data/nginx"

# 如果使用 curl 传递了参数，将参数赋值给 install_dir，否则使用默认安装位置
if [ $# -eq 1 ]; then
  install_dir="$1"
else
  read -p "请输入安装位置，默认地址为nginx：/home/data/nginx：" install_dir

  install_dir=${install_dir:-$default_install_dir}
fi

mkdir -p "$install_dir"
cd "$install_dir"

# 安装依赖
yum install -y pcre pcre-devel openssl perl-devel gcc-c++ perl zlib zlib-devel openssl-devel wget
yum groups install Development -y
yum install -y glib2-devel openssl-devel pcre-devel bzip2-devel gzip-devel pcre-devel libxslt* libxml2* gd-devel GeoIP-devel lua*  luajit-devel zip unzip
yum -y groupinstall 'Development Tools'
yum install -y  gcc g++ make cmake net-tools

# 创建nginx目录
mkdir -p $install_dir/cache/client_temp

cd $install_dir
wget http://www.lunrry.top:99/p/UUmISOOG0r/nginx-1.22.0.tar.gz
wget http://www.lunrry.top:99/p/gudyJLOuZ1/openssl-OpenSSL_1_1_1k.tar.gz
wget http://www.lunrry.top:99/p/SuNQR57JYF/lua-nginx-module-0.10.14.tar.gz
wget http://www.lunrry.top:99/p/xbeLWdyM3y/nginx-http-concat-master.zip
wget http://www.lunrry.top:99/p/GzHZFNN00t/LuaJIT-2.0.5.tar.gz
wget http://www.lunrry.top:99/p/Wmv3IkfHmI/ngx_devel_kit-0.3.1.tar.gz

# 安装LuaJIT
tar -zxf  LuaJIT-2.0.5.tar.gz
cd LuaJIT-2.0.5
make install PREFIX=/usr/local/LuaJIT

#设置环境变量
echo "#luajit" >> /etc/profile
echo 'export LUAJIT_INC=/usr/local/LuaJIT/include/luajit-2.0' >> /etc/profile
echo 'export LUAJIT_LIB=/usr/local/LuaJIT/lib' >> /etc/profile
source /etc/profile

cd $install_dir
tar xf ngx_devel_kit-0.3.1.tar.gz
tar xf lua-nginx-module-0.10.14.tar.gz
tar xf openssl-OpenSSL_1_1_1k.tar.gz
unzip nginx-http-concat-master.zip
tar xf nginx-1.22.0.tar.gz

cd nginx-1.22.0
export LUAJIT_LIB=/usr/local/LuaJIT/lib
export LUAJIT_INC=/usr/local/LuaJIT/include/luajit-2.0

./configure --prefix=/etc/nginx --sbin-path=/usr/sbin/nginx \
--modules-path=/usr/lib/nginx/modules --conf-path=/etc/nginx/nginx.conf \
--error-log-path=$install_dir/log/error.log --http-log-path=$install_dir/log/access.log \
--pid-path=$install_dir/run/nginx.pid --lock-path=$install_dir/run/nginx.lock \
--http-client-body-temp-path=$install_dir/cache/client_temp \
--http-proxy-temp-path=$install_dir/cache/proxy_temp \
--http-fastcgi-temp-path=$install_dir/cache/fastcgi_temp \
--http-uwsgi-temp-path=$install_dir/cache/uwsgi_temp \
--http-scgi-temp-path=$install_dir/cache/scgi_temp \
--user=nginx --group=nginx --with-http_ssl_module \
--with-http_realip_module --with-http_addition_module \
--with-http_sub_module --with-http_dav_module --with-http_flv_module \
--with-http_mp4_module --with-http_gunzip_module --with-http_gzip_static_module \
--with-http_random_index_module --with-http_secure_link_module --with-http_stub_status_module \
--with-http_auth_request_module --with-http_xslt_module=dynamic --with-http_image_filter_module=dynamic \
--with-http_geoip_module=dynamic --with-threads --with-stream --with-stream_ssl_module \
--with-stream_ssl_preread_module --with-stream_realip_module --with-stream_geoip_module=dynamic \
--with-http_slice_module --with-mail --with-mail_ssl_module --with-compat --with-file-aio --with-http_v2_module \
--with-openssl=$install_dir/openssl-OpenSSL_1_1_1k \
--add-module=$install_dir/lua-nginx-module-0.10.14 \
--add-module=$install_dir/ngx_devel_kit-0.3.1 \
--add-module=$install_dir/nginx-http-concat-master

make -j$CPU_NUM && make install
/usr/sbin/useradd -c "nginx user" -s /bin/false -r -d /var/lib/nginx nginx
export PATH=$PATH:/usr/sbin/nginx
echo 'export PATH=$PATH:/usr/sbin/nginx' >> /etc/profile
source /etc/profile

mv /etc/nginx/nginx.conf /etc/nginx/nginx.conf.bak
mkdir -p /etc/nginx/hosts/include
wget -P /etc/nginx/hosts/include http://www.lunrry.top:99/p/sDSjWt9GOL/cors.conf.part
wget -P /etc/nginx/hosts/include http://www.lunrry.top:99/p/gkd72HNdCn/front-app.conf
wget -P /etc/nginx/hosts/include http://www.lunrry.top:99/p/lWpbhEXaX6/tomcat_ylmh_proxy.conf
wget -P /etc/nginx/hosts/include http://www.lunrry.top:99/p/1h5SYGhkAY/tomcat_proxy_detail.part
wget -P /etc/nginx/hosts/include http://www.lunrry.top:99/p/NV4w330j1A/ifram_proxy.conf
wget -P /etc/nginx/hosts http://www.lunrry.top:99/p/EBX71va6Ss/mh.conf
wget -P /etc/nginx http://www.lunrry.top:99/p/ZjKjHpHMB3/nginx.conf
mkdir /etc/nginx/ssl

/usr/sbin/nginx

rm -rf LuaJIT-2.0.5.tar.gz ngx_devel_kit-0.3.1.tar.gz lua-nginx-module-0.10.14.tar.gz nginx-1.22.0.tar.gz nginx-http-concat-master.zip openssl-OpenSSL_1_1_1k.tar.gz LuaJIT-2.0.5 nginx-http-concat-master openssl-OpenSSL_1_1_1k lua-nginx-module-0.10.14 ngx_devel_kit-0.3.1
echo "如果无法访问请使用以下命令打开防火墙80端口："
echo "firewall-cmd --zone=public --add-port=80/tcp --permanent"
echo "firewall-cmd --reload"
