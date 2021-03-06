#!/bin/bash
exec 3>&1 4>&2
trap 'exec 2>&4 1>&3' 0 1 2 3
exec 1>/tmp/install.log 2>&1
# Everything below will go to the file '/tmp/install.log':

ROOTDBPASSWD="$(date +%s | sha256sum | base64 | head -c 32 ; echo)"

motdwarn="#!/bin/sh

echo \"INSTALLATION HAS NOT YET FINISHED. LET IT BE.\""
echo "$motdwarn" > '/etc/update-motd.d/99-install-not-finished'
chmod +x /etc/update-motd.d/99-install-not-finished

# Set the Server Timezone to CST
echo "America/Montreal" > /etc/timezone
dpkg-reconfigure -f noninteractive tzdata

# Update basic image
apt-get update
apt-get -y upgrade

# Install Nginx
apt-get install -y nginx

# Install PHP5-FPM
apt-get install -y php5-fpm

# Install MySQL Server in a Non-Interactive mode. Default root password will be "root"
echo "mysql-server mysql-server/root_password password $ROOTDBPASSWD" | sudo debconf-set-selections
echo "mysql-server mysql-server/root_password_again password $ROOTDBPASSWD" | sudo debconf-set-selections
apt-get -y install mysql-server

# Setup required database structure
mysql_install_db

# MySQL Secure Installation as defined via: mysql_secure_installation
mysql -uroot -p$ROOTDBPASSWD -e "DROP DATABASE test"
mysql -uroot -p$ROOTDBPASSWD -e "DELETE FROM mysql.user WHERE User='root' AND NOT IN ('localhost', '127.0.0.1', '::1')"
mysql -uroot -p$ROOTDBPASSWD -e "DELETE FROM mysql.user WHERE User=''"
mysql -uroot -p$ROOTDBPASSWD -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%'"
mysql -uroot -p$ROOTDBPASSWD -e "FLUSH PRIVILEGES"

# Install other Requirements
apt-get -y install php5-mysql php5-cli php5-gd curl git

# Create project folders
mkdir -p /www/sites/waq2016 /www/conf/waq2016 /www/logs/waq2016

# Create nginx cache folder
mkdir /usr/share/nginx/cache

# Download nginx conf
wget -O /www/conf/waq2016/nginx.conf https://github.com/paulcote/2016.waq.paulcote.net/raw/master/conf/nginx.conf

# Remove default and put WAQ conf
unlink /etc/nginx/sites-enabled/default
ln -s /www/conf/waq2016/nginx.conf /etc/nginx/sites-enabled/99-waq2016

rm /etc/update-motd.d/99-install-not-finished

wget -O /tmp/start.sh https://github.com/paulcote/2016.waq.paulcote.net/raw/master/scripts/start.sh
chmod +x /tmp/start.sh

echo "$ROOTDBPASSWD" > '/www/conf/waq2016/ROOTDBPASSWD'
echo "Install has been completed."
echo "You can run /tmp/start.sh to install base project if not using deploys."
echo "Root MYSQL password has been written to /www/conf/waq2016/ROOTDBPASSWD."
echo "Please change it and delete this file after running start script."
