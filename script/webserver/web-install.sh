#!/bin/bash
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

DOMAIN="farahamimah.net"
IP=$(hostname -I | awk '{print $1}')

echo -e "${YELLOW}[WEB] Memulai instalasi Web Server...${NC}"

# Install Apache2
apt install -y apache2

# Aktifkan modul
/usr/sbin/a2enmod rewrite
/usr/sbin/a2enmod ssl
/usr/sbin/a2enmod headers

# Backup konfigurasi
cp /etc/apache2/sites-available/000-default.conf \
   /etc/apache2/sites-available/000-default.conf.backup
echo -e "${GREEN}[WEB] Backup konfigurasi disimpan${NC}"

# Buat direktori web
mkdir -p /var/www/$DOMAIN/public_html
chmod -R 755 /var/www/$DOMAIN

# Buat halaman index
cat > /var/www/$DOMAIN/public_html/index.html << EOF
<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <title>$DOMAIN - Auto Server Provisioning</title>
    <style>
        body { font-family: Arial, sans-serif; text-align: center;
               background: #1a1a2e; color: #eee; padding: 50px; }
        h1 { color: #00d4ff; }
        .box { background: #16213e; padding: 30px;
               border-radius: 10px; display: inline-block; }
        .green { color: #00ff88; }
    </style>
</head>
<body>
    <div class="box">
        <h1>🚀 Auto Server Provisioning</h1>
        <h2 class="green">$DOMAIN</h2>
        <p>Web Server Apache2 berjalan di IP: <b>$IP</b></p>
        <p>Dibuat oleh: <b>farah1120</b></p>
        <p>OS: <b>Debian 12 (Bookworm)</b></p>
    </div>
</body>
</html>
EOF

# Buat Virtual Host
cat > /etc/apache2/sites-available/$DOMAIN.conf << EOF
<VirtualHost *:80>
    ServerName $DOMAIN
    ServerAlias www.$DOMAIN
    ServerAdmin webmaster@$DOMAIN
    DocumentRoot /var/www/$DOMAIN/public_html

    <Directory /var/www/$DOMAIN/public_html>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog \${APACHE_LOG_DIR}/$DOMAIN-error.log
    CustomLog \${APACHE_LOG_DIR}/$DOMAIN-access.log combined
</VirtualHost>
EOF

# Aktifkan Virtual Host
/usr/sbin/a2ensite $DOMAIN.conf
/usr/sbin/a2dissite 000-default.conf

# Restart Apache
systemctl restart apache2
systemctl enable apache2

if systemctl is-active --quiet apache2; then
    echo -e "${GREEN}[WEB] ✅ Web Server berhasil dikonfigurasi!${NC}"
    systemctl status apache2 --no-pager | grep "Active:"
    echo -e "${GREEN}[WEB] Akses: http://$IP${NC}"
else
    echo -e "${RED}[WEB] ❌ Web Server gagal!${NC}"
fi

echo -e "${GREEN}[WEB] Instalasi selesai!${NC}"
