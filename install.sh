#!/bin/bash
# ============================================
# Auto Server Provisioning Script
# Author  : farah1120
# Domain  : server.farahamimah.net
# OS      : Debian 12 (Bookworm)
# GitHub  : github.com/farah1120/auto-server-provisioning
# ============================================

# Warna terminal
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Cek apakah dijalankan sebagai root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}[ERROR] Script ini harus dijalankan sebagai root!${NC}"
   echo -e "Gunakan: sudo bash install.sh"
   exit 1
fi

# Banner
clear
echo -e "${CYAN}"
echo "=================================================="
echo "   AUTO SERVER PROVISIONING SCRIPT               "
echo "   Debian 12 (Bookworm)                          "
echo "   Domain: server.farahamimah.net                "
echo "=================================================="
echo -e "${NC}"

# Menu Utama
echo -e "${YELLOW}Pilih layanan yang ingin diinstall:${NC}"
echo ""
echo -e "  ${GREEN}[1]${NC} SSH Server (Hardening)"
echo -e "  ${GREEN}[2]${NC} DHCP Server"
echo -e "  ${GREEN}[3]${NC} DNS Server (BIND9)"
echo -e "  ${GREEN}[4]${NC} Web Server (Apache2/Nginx)"
echo -e "  ${GREEN}[5]${NC} Database Server (MySQL + phpMyAdmin)"
echo -e "  ${GREEN}[6]${NC} Mail Server (Postfix + Dovecot)"
echo -e "  ${GREEN}[7]${NC} Install SEMUA Layanan"
echo -e "  ${GREEN}[8]${NC} Generate Laporan Konfigurasi"
echo -e "  ${RED}[0]${NC} Keluar"
echo ""
read -p "Masukkan pilihan [0-8]: " choice

case $choice in
    1) bash script/ssh/ssh-install.sh ;;
    2) bash script/dhcp/dhcp-install.sh ;;
    3) bash script/dns/dns-install.sh ;;
    4) bash script/webserver/web-install.sh ;;
    5) bash script/database/db-install.sh ;;
    6) bash script/mailserver/mail-install.sh ;;
    7)
        bash script/ssh/ssh-install.sh
        bash script/dhcp/dhcp-install.sh
        bash script/dns/dns-install.sh
        bash script/webserver/web-install.sh
        bash script/database/db-install.sh
        bash script/mailserver/mail-install.sh
        ;;
    8) bash script/report.sh ;;
    0) echo -e "${RED}Keluar...${NC}"; exit 0 ;;
    *) echo -e "${RED}Pilihan tidak valid!${NC}"; exit 1 ;;
esac
