#!/usr/bin/env bash

ETHNAME=$(ip link | awk -F: '$0 !~ "lo|vir|wl|^[^0-9]"{gsub(" ","",$0);print $2;getline}') # Or declare a variable name of ethernet interface manually
IPADDRESS=192.168.10.51
DNSSERVER=192.168.10.3
GTWSERVER=192.168.10.1
MASKNET=255.255.255.0
NETWORK=192.168.10.0
SITE=b2b
DOMAIN=test.lab
MASTERHOST=b2b-01 #lsyncd
SLAVEHOST=b2b-02  #lsyncd
INSTALL_DIR=/home
HOSTNAME=$MASTERHOST.$DOMAIN
WEBDOMAIN=$SITE.$DOMAIN
ETC=$INSTALL_DIR/scripts/etc
VAR=$INSTALL_DIR/scripts/var
USR=$INSTALL_DIR/scripts/usr
NGINX=nginx-1.13.9

#Configure Network interface
#------------------------------------------------------
cp --backup=simple $ETC/sysconfig/network-scripts/ifcfg-ens192 /etc/sysconfig/network-scripts/ifcfg-$ETHNAME
sed -i "s/ETHNAME/$ETHNAME/g" /etc/sysconfig/network-scripts/ifcfg-$ETHNAME
sed -i "s/IPADDRESS/$IPADDRESS/g" /etc/sysconfig/network-scripts/ifcfg-$ETHNAME
sed -i "s/DNSSERVER/$DNSSERVER/g" /etc/sysconfig/network-scripts/ifcfg-$ETHNAME
sed -i "s/GTWSERVER/$GTWSERVER/g" /etc/sysconfig/network-scripts/ifcfg-$ETHNAME
sed -i "s/MASKNET/$MASKNET/g" /etc/sysconfig/network-scripts/ifcfg-$ETHNAME
chown -R root:root /etc/sysconfig/network-scripts/ifcfg-$ETHNAME
chmod -R 644 /etc/sysconfig/network-scripts/ifcfg-$ETHNAME
systemctl restart network
#------------------------------------------------------

#Configure Resolv.conf
#------------------------------------------------------
cp --backup=simple $ETC/resolv.conf /etc/resolv.conf
sed -i "s/DNSSERVER/$DNSSERVER/g" /etc/resolv.conf
chown -R root:root /etc/resolv.conf
chmod -R 644 /etc/resolv.conf
#------------------------------------------------------

#Configure hostname
#------------------------------------------------------
cp --backup=simple $ETC/hostname /etc/hostname
sed -i "s/HOSTNAME/$HOSTNAME/g" /etc/hostname
chown -R root:root /etc/hostname
chmod -R 644 /etc/hostname
#------------------------------------------------------

#Configure YUM
#------------------------------------------------------
cp --backup=simple $ETC/yum.repos.d/nginx.repo /etc/yum.repos.d/nginx.repo
chown -R root:root /etc/yum.repos.d/nginx.repo
chmod -R 644 /etc/yum.repos.d/nginx.repo
#------------------------------------------------------

yum update
yum -y install epel-release lua lua-devel pkgconfig asciidoc rsync lsyncd mc net-tools bind which ntpdate nginx php php-fpm mariadb mariadb-server php-mysql php-mysqli phpmyadmin php-mbstring php-mcrypt php-gd memcached php-pecl-memcached php-xcache proftpd proftpd-utils httpd httpd-devel gcc wget unzip gcc pcre-devel zlib-devel openssl-devel libxml2-devel libxslt-devel gd-devel perl-ExtUtils-Embed GeoIP-devel gperftools-devel
sed -i "s/SELINUX=enforcing/SELINUX=disabled/" /etc/selinux/config
/usr/sbin/setenforce 0

#Configure NTP over CRON
#------------------------------------------------------
cp --backup=simple $VAR/spool/cron/root /var/spool/cron/root
chown -R root:root /var/spool/cron/root
chmod -R 600 /var/spool/cron/root
#------------------------------------------------------

#Configure Firewall
#------------------------------------------------------
systemctl enable firewalld
systemctl start firewalld
firewall-cmd --permanent --add-port=80/tcp --add-port=443/tcp --add-port=8080/tcp --add-port=20-21/tcp --add-port=40900-40999/tcp --add-port=25/tcp --add-port=465/tcp --add-port=587/tcp --add-port=53/tcp
#------------------------------------------------------

#Configure PHP
#------------------------------------------------------
systemctl enable php-fpm
systemctl start php-fpm
cp --backup=simple $ETC/php.ini /etc/php.ini
chown -R root:root /etc/php.ini
chmod -R 644 /etc/php.ini
#------------------------------------------------------

#Configure MariaDB
#------------------------------------------------------
systemctl enable mariadb
systemctl start mariadb
echo Set ROOT PASSWORD to mariadb
mysqladmin -u root password
#------------------------------------------------------

#Configure ProFTPd 
#------------------------------------------------------
systemctl enable proftpd
systemctl start proftpd
mkdir -p /etc/proftpd.d
touch /etc/proftpd.d/ftpd.passwd
chown -R root:root /etc/proftpd.d/ftpd.passwd
chmod -R 640 /etc/proftpd.d/ftpd.passwd
echo Set ftpwww USER PASSWORD to ProFTPd
ftpasswd --passwd --file=/etc/proftpd.d/ftpd.passwd --name=ftpwww --uid=48 --gid=48 --home=/var/www --shell=/sbin/nologin
cp --backup=simple $ETC/proftpd.conf /etc/proftpd.conf
chown -R root:root /etc/proftpd.conf
chmod -R 640 /etc/proftpd.conf
#------------------------------------------------------

#Configure NAMED
#------------------------------------------------------
cp --backup=simple $ETC/named.conf /etc/named.conf
sed -i "s/NETWORK/$NETWORK/g" /etc/named.conf
sed -i "s/DOMAIN/$DOMAIN/g" /etc/named.conf
chown -R root:root /etc/named.conf
chmod -R 644 /etc/named.conf
mkdir -p /var/named/master
cp --backup=simple $VAR/named/master/test.lab /var/named/master/$DOMAIN
sed -i "s/DOMAIN/$DOMAIN/g" /var/named/master/$DOMAIN
sed -i "s/IPADDRESS/$IPADDRESS/g" /var/named/master/$DOMAIN
sed -i "s/SITE/$SITE/g" /var/named/master/$DOMAIN
sed -i "s/MASTERHOST/$MASTERHOST/g" /var/named/master/$DOMAIN
sed -i "s/DNSSERVER/$DNSSERVER/g" /var/named/master/$DOMAIN
chown -R root:root /var/named/master/$DOMAIN
chmod -R 644 /var/named/master/$DOMAIN
systemctl enable named
systemctl start named
/usr/sbin/rndc reload
#------------------------------------------------------

#Configure NGINX
#------------------------------------------------------
systemctl enable nginx
systemctl start nginx
cp --backup=simple $ETC/nginx/nginx.conf /etc/nginx/nginx.conf
cp --backup=simple $USR/share/nginx/html/index.php /usr/share/nginx/html/index.php
cp --backup=simple $ETC/nginx/conf.d/default.conf /etc/nginx/conf.d/default.conf
chown -R root:root /etc/nginx/nginx.conf
chmod -R 644 /etc/nginx/nginx.conf
chown -R root:root /usr/share/nginx/html/index.php
chmod -R 644 /usr/share/nginx/html/index.php
chown -R root:root /etc/nginx/conf.d/default.conf
chmod -R 644 /etc/nginx/conf.d/default.conf
#------------------------------------------------------

#Configure Nginx http2
#------------------------------------------------------
wget http://nginx.org/download/$NGINX.tar.gz
wget --no-check-certificate https://www.openssl.org/source/openssl-1.1.0c.tar.gz
tar -xvf $NGINX.tar.gz && rm ./$NGINX.tar.gz
tar -xvf openssl-1.1.0c.tar.gz && rm ./openssl-1.1.0c.tar.gz
cd $NGINX
./configure --prefix=/etc/nginx --sbin-path=/usr/sbin/nginx --modules-path=/usr/lib64/nginx/modules --conf-path=/etc/nginx/nginx.conf --error-log-path=/var/log/nginx/error.log --http-log-path=/var/log/nginx/access.log --pid-path=/var/run/nginx.pid --lock-path=/var/run/nginx.lock --http-client-body-temp-path=/var/cache/nginx/client_temp --http-proxy-temp-path=/var/cache/nginx/proxy_temp --http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp --http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp --http-scgi-temp-path=/var/cache/nginx/scgi_temp --user=nginx --group=nginx --with-file-aio --with-threads --with-ipv6 --with-http_addition_module --with-http_auth_request_module --with-http_dav_module --with-http_flv_module --with-http_gunzip_module --with-http_gzip_static_module --with-http_mp4_module --with-http_random_index_module --with-http_realip_module --with-http_secure_link_module --with-http_slice_module --with-http_ssl_module --with-http_stub_status_module --with-http_sub_module --with-http_v2_module --with-mail --with-mail_ssl_module --with-stream --with-stream_ssl_module --with-cc-opt='-O2 -g -pipe -Wall -Wp,-D_FORTIFY_SOURCE=2 -fexceptions -fstack-protector --param=ssp-buffer-size=4 -m64 -mtune=generic' --with-openssl=/$INSTALL_DIR/openssl-1.1.0c
make install
cd ..
rm -R ./$NGINX openssl-*
#mkdir -p /etc/nginx/ssl
#openssl req -new -x509 -days 1461 -nodes -out /etc/nginx/ssl/cert.pem -keyout /etc/nginx/ssl/cert.key -subj "/C=UA/ST=Kiev/L=Kiev/O=Global Security/OU=IT Department/CN=test.test.lab/CN=test"
#------------------------------------------------------

#Configure Apache
#------------------------------------------------------
systemctl enable httpd
systemctl start httpd
cp --backup=simple $ETC/httpd/conf/httpd.conf /etc/httpd/conf/httpd.conf
cp --backup=simple $VAR/www/html/index.php /var/www/html/index.php
chown -R root:root /etc/httpd/conf/httpd.conf
chmod -R 644 /etc/httpd/conf/httpd.conf
chown -R root:root /var/www/html/index.php
chmod -R 644 /var/www/html/index.php
cd /usr/local/src
wget https://github.com/gnif/mod_rpaf/archive/stable.zip
unzip -o stable.zip
cd ./mod_rpaf-stable && make && make install
cp --backup=simple $ETC/httpd/conf.d/mod_rpaf.conf /etc/httpd/conf.d/mod_rpaf.conf
chown -R root:root /etc/httpd/conf.d/mod_rpaf.conf
chmod -R 644 /etc/httpd/conf.d/mod_rpaf.conf
#------------------------------------------------------

#Configure Postfix
#------------------------------------------------------
systemctl enable postfix
systemctl start postfix
cp --backup=simple $ETC/postfix/main.cf /etc/postfix/main.cf
sed -i "s/DOMAIN/$DOMAIN/g" /etc/postfix/main.cf
chown -R root:root /etc/postfix/main.cf
chmod -R 644 /etc/postfix/main.cf
cp --backup=simple $ETC/postfix/generic_map /etc/postfix/generic_map
sed -i "s/DOMAIN/$DOMAIN/g" /etc/postfix/generic_map
chown -R root:root /etc/postfix/generic_map
chmod -R 644 /etc/postfix/generic_map
postmap /etc/postfix/generic_map
#------------------------------------------------------

#Configure phpMyAdmin
#------------------------------------------------------
cp --backup=simple $ETC/nginx/conf.d/phpMyAdmin.conf /etc/nginx/conf.d/phpMyAdmin.conf
sed -i "s/DOMAIN/$DOMAIN/g" /etc/httpd/conf.d/phpMyAdmin.conf
chown -R root:root /etc/nginx/conf.d/phpMyAdmin.conf
chmod -R 644 /etc/nginx/conf.d/phpMyAdmin.conf
#-----------------------------------------------------

#Configure First Site
#------------------------------------------------------
cp --backup=simple $ETC/nginx/conf.d/$SITE.conf /etc/nginx/conf.d/$SITE.conf
cp --backup=simple $ETC/httpd/conf.d/$SITE.conf /etc/httpd/conf.d/$SITE.conf
sed -i "s/WEBDOMAIN/$WEBDOMAIN/g" /etc/httpd/conf.d/$SITE.conf
sed -i "s/SITE/$SITE/g" /etc/httpd/conf.d/$SITE.conf
sed -i "s/WEBDOMAIN/$WEBDOMAIN/g" /etc/nginx/conf.d/$SITE.conf
sed -i "s/SITE/$SITE/g" /etc/nginx/conf.d/$SITE.conf
chown -R root:root /etc/nginx/conf.d/$SITE.conf
chmod -R 644 /etc/nginx/conf.d/$SITE.conf
chown -R root:root /etc/httpd/conf.d/$SITE.conf
chmod -R 644 /etc/httpd/conf.d/$SITE.conf
mkdir -p /var/www/$SITE/{www,tmp,log}
mkdir -p /var/www/$SITE/log/{nginx,apache}
echo '<?php echo "<h1>Hello from $MASTERHOST</h1>"; ?>' >> /var/www/$SITE/www/index.php
chown -R apache:apache /var/www/$SITE
chmod -R 775 /var/www/$SITE
#------------------------------------------------------

#Configure SSHd
#------------------------------------------------------
#echo 'PubkeyAuthentication yes' >> /etc/ssh/sshd_config
#ssh-keygen -N "" -f /root/.ssh/id_rsa
echo -e 'y\n' | ssh-keygen -f $HOME/.ssh/id_rsa -t rsa -N ''
ssh-copy-id -i /root/.ssh/id_rsa.pub root@$SLAVEHOST
#------------------------------------------------------

#Configure lsyncd
#------------------------------------------------------
mkdir -p /var/log/lsyncd
cp --backup=simple $ETC/lsyncd.conf /etc/lsyncd.conf
sed -i "s/SLAVEHOST/$SLAVEHOST/g" /etc/lsyncd.conf
chown -R root:root /etc/lsyncd.conf
chmod -R 644 /etc/lsyncd.conf
systemctl enable lsyncd
#------------------------------------------------------

#------------------------------------------------------
#Configure Restart service
#------------------------------------------------------
systemctl restart nginx
systemctl restart php-fpm
systemctl restart mariadb
systemctl restart memcached
systemctl restart proftpd
systemctl restart httpd
systemctl restart named
systemctl restart postfix
firewall-cmd --reload
/usr/sbin/rndc reload
#------------------------------------------------------



