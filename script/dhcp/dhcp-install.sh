#!/bin/bash
# ============================================
# DHCP Server Installation Script
# ============================================

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}[DHCP] Memulai instalasi DHCP Server...${NC}"

# Install isc-dhcp-server
apt install -y isc-dhcp-server

# Deteksi nama interface
IFACE=$(ip -o link show | awk -F': ' '{print $2}' | grep -v lo | head -1)
echo -e "${GREEN}[DHCP] Interface terdeteksi: $IFACE${NC}"

# Konfigurasi interface untuk DHCP
cat > /etc/default/isc-dhcp-server << EOF
INTERFACESv4="$IFACE"
INTERFACESv6=""
EOF

# Backup konfigurasi asli
cp /etc/dhcp/dhcpd.conf /etc/dhcp/dhcpd.conf.backup
echo -e "${GREEN}[DHCP] Backup konfigurasi disimpan${NC}"

# Konfigurasi DHCP Server
cat > /etc/dhcp/dhcpd.conf << 'EOF'
# ============================================
# DHCP Server Configuration
# Auto Server Provisioning - farahamimah.net
# ============================================

default-lease-time 600;
max-lease-time 7200;
authoritative;

subnet 192.168.1.0 netmask 255.255.255.0 {
    range 192.168.1.100 192.168.1.200;
    option routers 192.168.1.1;
    option domain-name-servers 192.168.1.1, 8.8.8.8;
    option domain-name "farahamimah.net";
    option broadcast-address 192.168.1.255;
}
EOF

# Restart & enable DHCP
systemctl restart isc-dhcp-server
systemctl enable isc-dhcp-server

# Verifikasi
if systemctl is-active --quiet isc-dhcp-server; then
    echo -e "${GREEN}[DHCP] ✅ DHCP Server berhasil dikonfigurasi!${NC}"
    echo -e "${GREEN}[DHCP] Status: AKTIF${NC}"
    systemctl status isc-dhcp-server --no-pager | grep "Active:"
else
    echo -e "${RED}[DHCP] ❌ DHCP Server gagal! Cek log: journalctl -xe${NC}"
fi

echo -e "${GREEN}[DHCP] Instalasi selesai!${NC}"
