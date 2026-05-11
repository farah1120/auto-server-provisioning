#!/bin/bash
# ============================================
# Report Generator Script
# Auto Server Provisioning - farahamimah.net
# ============================================

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

DOMAIN="farahamimah.net"
IP=$(hostname -I | awk '{print $1}')
HOSTNAME=$(hostname)
DATE=$(date '+%Y-%m-%d %H:%M:%S')
REPORT_DIR="reports"
REPORT_TXT="$REPORT_DIR/report-$(date '+%Y%m%d-%H%M%S').txt"
REPORT_HTML="$REPORT_DIR/report-$(date '+%Y%m%d-%H%M%S').html"

mkdir -p $REPORT_DIR

echo -e "${YELLOW}[REPORT] Generating laporan konfigurasi server...${NC}"

# Cek status service
check_service() {
    if systemctl is-active --quiet $1; then
        echo "AKTIF"
    else
        echo "TIDAK AKTIF"
    fi
}

SSH_STATUS=$(check_service ssh)
DHCP_STATUS=$(check_service isc-dhcp-server)
DNS_STATUS=$(check_service named)
WEB_STATUS=$(check_service apache2)
DB_STATUS=$(check_service mariadb)
MAIL_STATUS=$(check_service postfix)
DOVECOT_STATUS=$(check_service dovecot)

# ============================================
# Generate TXT Report
# ============================================
cat > $REPORT_TXT << EOF
==================================================
  AUTO SERVER PROVISIONING - LAPORAN KONFIGURASI
==================================================
Tanggal   : $DATE
Hostname  : $HOSTNAME
IP Address: $IP
Domain    : $DOMAIN
OS        : $(cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)
Kernel    : $(uname -r)
--------------------------------------------------

[RESOURCE SISTEM]
CPU Usage : $(top -bn1 | grep "Cpu(s)" | awk '{print $2}')%
RAM Total : $(free -h | awk '/^Mem:/{print $2}')
RAM Used  : $(free -h | awk '/^Mem:/{print $3}')
RAM Free  : $(free -h | awk '/^Mem:/{print $4}')
Disk Total: $(df -h / | awk 'NR==2{print $2}')
Disk Used : $(df -h / | awk 'NR==2{print $3}')
Disk Free : $(df -h / | awk 'NR==2{print $4}')

[STATUS LAYANAN]
SSH Server (OpenSSH)    : $SSH_STATUS
DHCP Server             : $DHCP_STATUS
DNS Server (BIND9)      : $DNS_STATUS
Web Server (Apache2)    : $WEB_STATUS
Database (MariaDB)      : $DB_STATUS
Mail Server (Postfix)   : $MAIL_STATUS
Mail Server (Dovecot)   : $DOVECOT_STATUS

[KONFIGURASI JARINGAN]
$(ip a | grep -E "inet |ether")

[KONFIGURASI SSH]
Port    : $(grep "^Port" /etc/ssh/sshd_config 2>/dev/null || echo "22 (default)")
Protocol: 2

[KONFIGURASI DNS]
Domain  : $DOMAIN
Zone    : /etc/bind/zones/db.$DOMAIN

[KONFIGURASI WEB]
DocumentRoot: /var/www/$DOMAIN/public_html
VirtualHost : $DOMAIN

[KONFIGURASI DATABASE]
Engine  : MariaDB
Database: provisioning_db
User    : farah@localhost

[KONFIGURASI MAIL]
SMTP (Postfix)  : Port 25
IMAP (Dovecot)  : Port 143
POP3 (Dovecot)  : Port 110
Maildir         : ~/Maildir

==================================================
  Dibuat oleh: farah1120
  GitHub: github.com/farah1120/auto-server-provisioning
==================================================
EOF

echo -e "${GREEN}[REPORT] ✅ Laporan TXT: $REPORT_TXT${NC}"

# ============================================
# Generate HTML Report
# ============================================

status_badge() {
    if [ "$1" = "AKTIF" ]; then
        echo "<span class='aktif'>● AKTIF</span>"
    else
        echo "<span class='nonaktif'>● TIDAK AKTIF</span>"
    fi
}

cat > $REPORT_HTML << EOF
<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <title>Server Report - $DOMAIN</title>
    <style>
        body { font-family: Arial, sans-serif; background: #1a1a2e; color: #eee; margin: 0; padding: 20px; }
        h1 { color: #00d4ff; text-align: center; }
        h2 { color: #00d4ff; border-bottom: 1px solid #444; padding-bottom: 5px; }
        .container { max-width: 900px; margin: 0 auto; }
        .card { background: #16213e; border-radius: 10px; padding: 20px; margin: 15px 0; }
        table { width: 100%; border-collapse: collapse; }
        th { background: #0f3460; padding: 10px; text-align: left; }
        td { padding: 8px 10px; border-bottom: 1px solid #333; }
        .aktif { color: #00ff88; font-weight: bold; }
        .nonaktif { color: #ff4444; font-weight: bold; }
        .info { color: #aaa; font-size: 12px; text-align: center; margin-top: 20px; }
    </style>
</head>
<body>
<div class="container">
    <h1>🖥️ Auto Server Provisioning Report</h1>
    <p style="text-align:center; color:#aaa;">$DATE | $HOSTNAME | $IP</p>

    <div class="card">
        <h2>📋 Informasi Server</h2>
        <table>
            <tr><th>Item</th><th>Detail</th></tr>
            <tr><td>Hostname</td><td>$HOSTNAME</td></tr>
            <tr><td>IP Address</td><td>$IP</td></tr>
            <tr><td>Domain</td><td>$DOMAIN</td></tr>
            <tr><td>OS</td><td>$(cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)</td></tr>
            <tr><td>Kernel</td><td>$(uname -r)</td></tr>
        </table>
    </div>

    <div class="card">
        <h2>💾 Resource Sistem</h2>
        <table>
            <tr><th>Resource</th><th>Total</th><th>Digunakan</th><th>Bebas</th></tr>
            <tr>
                <td>RAM</td>
                <td>$(free -h | awk '/^Mem:/{print $2}')</td>
                <td>$(free -h | awk '/^Mem:/{print $3}')</td>
                <td>$(free -h | awk '/^Mem:/{print $4}')</td>
            </tr>
            <tr>
                <td>Disk</td>
                <td>$(df -h / | awk 'NR==2{print $2}')</td>
                <td>$(df -h / | awk 'NR==2{print $3}')</td>
                <td>$(df -h / | awk 'NR==2{print $4}')</td>
            </tr>
        </table>
    </div>

    <div class="card">
        <h2>⚙️ Status Layanan</h2>
        <table>
            <tr><th>Layanan</th><th>Status</th><th>Port</th></tr>
            <tr><td>SSH Server (OpenSSH)</td><td>$(status_badge "$SSH_STATUS")</td><td>22</td></tr>
            <tr><td>DHCP Server</td><td>$(status_badge "$DHCP_STATUS")</td><td>67</td></tr>
            <tr><td>DNS Server (BIND9)</td><td>$(status_badge "$DNS_STATUS")</td><td>53</td></tr>
            <tr><td>Web Server (Apache2)</td><td>$(status_badge "$WEB_STATUS")</td><td>80</td></tr>
            <tr><td>Database (MariaDB)</td><td>$(status_badge "$DB_STATUS")</td><td>3306</td></tr>
            <tr><td>Mail Server (Postfix)</td><td>$(status_badge "$MAIL_STATUS")</td><td>25</td></tr>
            <tr><td>Dovecot IMAP/POP3</td><td>$(status_badge "$DOVECOT_STATUS")</td><td>143/110</td></tr>
        </table>
    </div>

    <p class="info">
        Dibuat oleh: farah1120 |
        GitHub: github.com/farah1120/auto-server-provisioning |
        $DATE
    </p>
</div>
</body>
</html>
EOF

echo -e "${GREEN}[REPORT] ✅ Laporan HTML: $REPORT_HTML${NC}"
echo -e "${CYAN}[REPORT] Buka laporan HTML di browser untuk tampilan lengkap!${NC}"
echo -e "${GREEN}[REPORT] Generate laporan selesai!${NC}"
