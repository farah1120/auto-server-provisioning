#!/bin/bash
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

DOMAIN="farahamimah.net"
HOSTNAME="server"
IP=$(hostname -I | awk '{print $1}')

echo -e "${YELLOW}[DNS] Memulai instalasi DNS Server (BIND9)...${NC}"
echo -e "${YELLOW}[DNS] Domain: $DOMAIN | IP: $IP${NC}"

apt install -y bind9 bind9utils bind9-doc dnsutils

cp /etc/bind/named.conf.options /etc/bind/named.conf.options.backup
cp /etc/bind/named.conf.local /etc/bind/named.conf.local.backup
echo -e "${GREEN}[DNS] Backup konfigurasi disimpan${NC}"

cat > /etc/bind/named.conf.options << EOF
options {
    directory "/var/cache/bind";
    recursion yes;
    allow-recursion { any; };
    listen-on { any; };
    forwarders {
        8.8.8.8;
        8.8.4.4;
    };
    dnssec-validation auto;
};
EOF

cat > /etc/bind/named.conf.local << EOF
zone "$DOMAIN" {
    type master;
    file "/etc/bind/zones/db.$DOMAIN";
};
zone "1.168.192.in-addr.arpa" {
    type master;
    file "/etc/bind/zones/db.192.168.1";
};
EOF

mkdir -p /etc/bind/zones

cat > /etc/bind/zones/db.$DOMAIN << EOF
\$TTL    604800
@       IN      SOA     $HOSTNAME.$DOMAIN. root.$DOMAIN. (
                        2026051001
                        604800
                        86400
                        2419200
                        604800 )
@       IN      NS      $HOSTNAME.$DOMAIN.
@       IN      A       $IP
$HOSTNAME IN    A       $IP
www     IN      A       $IP
mail    IN      A       $IP
ftp     IN      A       $IP
EOF

REVERSE=$(echo $IP | awk -F. '{print $4}')
cat > /etc/bind/zones/db.192.168.1 << EOF
\$TTL    604800
@       IN      SOA     $HOSTNAME.$DOMAIN. root.$DOMAIN. (
                        2026051001
                        604800
                        86400
                        2419200
                        604800 )
@       IN      NS      $HOSTNAME.$DOMAIN.
$REVERSE IN     PTR     $HOSTNAME.$DOMAIN.
EOF

named-checkconf
named-checkzone $DOMAIN /etc/bind/zones/db.$DOMAIN
named-checkzone 1.168.192.in-addr.arpa /etc/bind/zones/db.192.168.1

systemctl restart named
systemctl enable named

if systemctl is-active --quiet named; then
    echo -e "${GREEN}[DNS] ✅ DNS Server berhasil dikonfigurasi!${NC}"
    systemctl status named --no-pager | grep "Active:"
else
    echo -e "${RED}[DNS] ❌ DNS Server gagal!${NC}"
fi

echo -e "${GREEN}[DNS] Instalasi selesai!${NC}"
