#!/bin/bash
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

DOMAIN="farahamimah.net"
MYSQL_ROOT_PASS="Admin1234!"

echo -e "${YELLOW}[DB] Memulai instalasi Database Server...${NC}"

# Install MariaDB
apt install -y default-mysql-server default-mysql-client
echo -e "${GREEN}[DB] MariaDB terinstall${NC}"

# Perbaiki autentikasi root
echo -e "${YELLOW}[DB] Mengkonfigurasi root MariaDB...${NC}"
cat > /etc/mysql/debian.cnf << EOF
[client]
host     = localhost
user     = root
password = $MYSQL_ROOT_PASS
socket   = /var/run/mysqld/mysqld.sock
[mysql_upgrade]
host     = localhost
user     = root
password = $MYSQL_ROOT_PASS
socket   = /var/run/mysqld/mysqld.sock
EOF

systemctl restart mariadb

# Set password root & amankan MariaDB
mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '$MYSQL_ROOT_PASS';"
mysql -u root -p"$MYSQL_ROOT_PASS" -e "DELETE FROM mysql.user WHERE User='';"
mysql -u root -p"$MYSQL_ROOT_PASS" -e "DROP DATABASE IF EXISTS test;"
mysql -u root -p"$MYSQL_ROOT_PASS" -e "FLUSH PRIVILEGES;"
echo -e "${GREEN}[DB] Root password dikonfigurasi${NC}"

# Buat database & user project
mysql -u root -p"$MYSQL_ROOT_PASS" -e "CREATE DATABASE IF NOT EXISTS provisioning_db;"
mysql -u root -p"$MYSQL_ROOT_PASS" -e "CREATE USER IF NOT EXISTS 'farah'@'localhost' IDENTIFIED BY 'Farah1234!';"
mysql -u root -p"$MYSQL_ROOT_PASS" -e "GRANT ALL PRIVILEGES ON provisioning_db.* TO 'farah'@'localhost';"
mysql -u root -p"$MYSQL_ROOT_PASS" -e "FLUSH PRIVILEGES;"
echo -e "${GREEN}[DB] Database provisioning_db & user farah dibuat${NC}"

# Install phpMyAdmin (tanpa dbconfig)
echo -e "${YELLOW}[DB] Menginstall phpMyAdmin...${NC}"
echo "phpmyadmin phpmyadmin/dbconfig-install boolean false" | debconf-set-selections
echo "phpmyadmin phpmyadmin/app-password-confirm password $MYSQL_ROOT_PASS" | debconf-set-selections
echo "phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2" | debconf-set-selections
apt install -y phpmyadmin php libapache2-mod-php

# Update debian.cnf agar phpMyAdmin bisa konek
cat > /etc/mysql/debian.cnf << EOF
[client]
host     = localhost
user     = root
password = $MYSQL_ROOT_PASS
socket   = /var/run/mysqld/mysqld.sock
[mysql_upgrade]
host     = localhost
user     = root
password = $MYSQL_ROOT_PASS
socket   = /var/run/mysqld/mysqld.sock
EOF

# Link phpMyAdmin ke Apache
ln -sf /usr/share/phpmyadmin /var/www/html/phpmyadmin

# Restart services
systemctl restart mariadb
systemctl restart apache2

# Verifikasi
if systemctl is-active --quiet mariadb; then
    echo -e "${GREEN}[DB] ✅ Database Server berhasil dikonfigurasi!${NC}"
    systemctl status mariadb --no-pager | grep "Active:"
    echo -e "${GREEN}[DB] phpMyAdmin : http://192.168.1.22/phpmyadmin${NC}"
    echo -e "${GREEN}[DB] Root       : root / $MYSQL_ROOT_PASS${NC}"
    echo -e "${GREEN}[DB] User app   : farah / Farah1234!${NC}"
else
    echo -e "${RED}[DB] ❌ MariaDB gagal! Cek: journalctl -xe${NC}"
fi

echo -e "${GREEN}[DB] Instalasi selesai!${NC}"
