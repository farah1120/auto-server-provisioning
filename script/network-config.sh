#!/bin/bash
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

INTERFACE=$(ip -o link show | awk -F': ' '{print $2}' | grep -v lo | head -1)
PROXMOX_IP=""

clear
echo -e "${CYAN}"
echo "=================================================="
echo "   NETWORK CONFIGURATION"
echo "   Auto Server Provisioning - farahamimah.net"
echo "=================================================="
echo -e "${NC}"
echo -e "${YELLOW}Interface terdeteksi : $INTERFACE${NC}"
echo -e "${YELLOW}IP Saat Ini          : $(hostname -I | awk '{print $1}')${NC}"
echo ""
echo -e "Pilih jaringan yang digunakan:"
echo ""
echo -e "  ${GREEN}[1]${NC} WiFi Rumah  | Debian: 192.168.1.43 | Proxmox: 192.168.1.20"
echo -e "  ${GREEN}[2]${NC} WiFi LAB    | Debian: 10.11.8.43   | Proxmox: 10.11.8.20"
echo -e "  ${GREEN}[3]${NC} WiFi Kelas  | Debian: 10.11.5.43   | Proxmox: 10.11.5.20"
echo -e "  ${GREEN}[4]${NC} Kabel LAN   | Debian: 10.3.2.43    | Proxmox: 10.3.2.20"
echo -e "  ${GREEN}[5]${NC} Custom      | Input manual"
echo -e "  ${GREEN}[6]${NC} DHCP        | Otomatis"
echo -e "  ${RED}[0]${NC} Keluar"
echo ""
read -p "Masukkan pilihan [0-6]: " choice

set_static_ip() {
    local IP=$1
    local GW=$2
    local DNS=$3
    local MASK=$4

    cat > /etc/network/interfaces << INTERFACES
source /etc/network/interfaces.d/*
auto lo
iface lo inet loopback
auto $INTERFACE
iface $INTERFACE inet static
    address $IP
    netmask $MASK
    gateway $GW
    dns-nameservers $DNS 8.8.8.8
INTERFACES

    ifdown $INTERFACE 2>/dev/null
    ifup $INTERFACE 2>/dev/null
    sleep 2

    sed -i "/server.farahamimah.net/d" /etc/hosts
    sed -i "/proxmox.farahamimah.net/d" /etc/hosts
    echo "$IP $PROXMOX_IP server.farahamimah.net server" >> /etc/hosts
    echo "$PROXMOX_IP proxmox.farahamimah.net proxmox" >> /etc/hosts
}

set_dhcp() {
    cat > /etc/network/interfaces << INTERFACES
source /etc/network/interfaces.d/*
auto lo
iface lo inet loopback
auto $INTERFACE
iface $INTERFACE inet dhcp
INTERFACES

    ifdown $INTERFACE 2>/dev/null
    ifup $INTERFACE 2>/dev/null
    sleep 3
}

case $choice in
    1)
        PROXMOX_IP="192.168.1.20"
        echo -e "${YELLOW}[NET] Konfigurasi WiFi Rumah...${NC}"
        set_static_ip "192.168.1.43" "192.168.1.1" "192.168.1.1" "255.255.255.0"
        ;;
    2)
        PROXMOX_IP="10.11.8.20"
        echo -e "${YELLOW}[NET] Konfigurasi WiFi LAB...${NC}"
        set_static_ip "10.11.8.43" "10.11.8.1" "10.11.8.1" "255.255.255.0"
        ;;
    3)
        PROXMOX_IP="10.11.5.20"
        echo -e "${YELLOW}[NET] Konfigurasi WiFi Kelas...${NC}"
        set_static_ip "10.11.5.43" "10.11.5.1" "10.11.5.1" "255.255.255.0"
        ;;
    4)
        PROXMOX_IP="10.3.2.20"
        echo -e "${YELLOW}[NET] Konfigurasi Kabel LAN...${NC}"
        set_static_ip "10.3.2.43" "10.3.2.1" "10.3.2.1" "255.255.255.0"
        ;;
    5)
        read -p "IP Debian   : " CIP
        read -p "Netmask     : " CMASK
        read -p "Gateway     : " CGW
        read -p "DNS         : " CDNS
        read -p "IP Proxmox  : " PROXMOX_IP
        set_static_ip "$CIP" "$CGW" "$CDNS" "$CMASK"
        ;;
    6)
        PROXMOX_IP="(cek manual)"
        set_dhcp
        ;;
    0)
        exit 0
        ;;
    *)
        echo -e "${RED}Pilihan tidak valid!${NC}"
        exit 1
        ;;
esac

sleep 2
IP_NOW=$(hostname -I | awk '{print $1}')
echo ""
echo -e "${CYAN}================================================${NC}"
echo -e "${GREEN} Konfigurasi Jaringan Selesai!${NC}"
echo -e "${CYAN}------------------------------------------------${NC}"
echo -e "  IP Debian   : ${GREEN}$IP_NOW${NC}"
echo -e "  IP Proxmox  : ${GREEN}$PROXMOX_IP${NC}"
echo -e "  Hostname    : ${GREEN}$(hostname)${NC}"
echo -e "  Domain      : ${GREEN}server.farahamimah.net${NC}"
echo -e "${CYAN}------------------------------------------------${NC}"
echo -e "  Web         : http://$IP_NOW"
echo -e "  phpMyAdmin  : http://$IP_NOW/phpmyadmin"
echo -e "  SSH         : ssh farah@$IP_NOW"
echo -e "  Proxmox     : https://$PROXMOX_IP:8006"
echo -e "${CYAN}================================================${NC}"
