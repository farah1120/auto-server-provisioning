#!/bin/bash
# ============================================
# Health Check & Auto Restart Service Script
# Auto Server Provisioning - farahamimah.net
# Berjalan otomatis via crontab setiap 5 menit
# ============================================

# ============================================
# KONFIGURASI
# ============================================
DOMAIN="farahamimah.net"
LOG="/var/log/auto-server-provisioning/healthcheck.log"
MAX_LOG_SIZE=5242880  # 5MB maksimal ukuran log

# Daftar layanan yang dipantau
# Format: "nama_service:nama_tampilan:port"
SERVICES=(
    "ssh:SSH Server:22"
    "isc-dhcp-server:DHCP Server:67"
    "named:DNS Server:53"
    "apache2:Web Server:80"
    "mariadb:Database Server:3306"
    "postfix:Mail SMTP:25"
    "dovecot:Mail IMAP/POP3:143"
)
# ============================================

# Buat folder log
mkdir -p /var/log/auto-server-provisioning

# Rotasi log jika terlalu besar
if [ -f "$LOG" ] && [ $(stat -f%z "$LOG" 2>/dev/null || stat -c%s "$LOG") -gt $MAX_LOG_SIZE ]; then
    mv $LOG $LOG.old
    echo "$(date '+%Y-%m-%d %H:%M:%S') | Log dirotasi" > $LOG
fi

# ============================================
# FUNGSI - Cek dan restart service
# ============================================
check_and_restart() {
    local SERVICE=$1
    local DISPLAY_NAME=$2
    local PORT=$3

    # Cek apakah service aktif
    if ! systemctl is-active --quiet $SERVICE 2>/dev/null; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') | ❌ $DISPLAY_NAME MATI! Mencoba restart..." >> $LOG

        # Coba restart
        systemctl restart $SERVICE 2>/dev/null
        sleep 3

        # Cek lagi setelah restart
        if systemctl is-active --quiet $SERVICE 2>/dev/null; then
            echo "$(date '+%Y-%m-%d %H:%M:%S') | ✅ $DISPLAY_NAME berhasil direstart!" >> $LOG
            return 0
        else
            echo "$(date '+%Y-%m-%d %H:%M:%S') | 🚨 $DISPLAY_NAME GAGAL direstart! Perlu penanganan manual!" >> $LOG
            return 1
        fi
    fi
    return 0
}

# ============================================
# FUNGSI - Cek resource sistem
# ============================================
check_resources() {
    # Cek CPU usage
    CPU=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)

    # Cek RAM usage
    RAM_TOTAL=$(free -m | awk '/^Mem:/{print $2}')
    RAM_USED=$(free -m | awk '/^Mem:/{print $3}')
    RAM_PERCENT=$((RAM_USED * 100 / RAM_TOTAL))

    # Cek Disk usage
    DISK_PERCENT=$(df -h / | awk 'NR==2{print $5}' | cut -d'%' -f1)

    # Warning jika resource tinggi
    if [ "$RAM_PERCENT" -gt 90 ]; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') | ⚠️  RAM TINGGI: ${RAM_PERCENT}% (${RAM_USED}MB/${RAM_TOTAL}MB)" >> $LOG
    fi

    if [ "$DISK_PERCENT" -gt 90 ]; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') | ⚠️  DISK PENUH: ${DISK_PERCENT}%" >> $LOG
    fi
}

# ============================================
# FUNGSI - Generate ringkasan status
# ============================================
generate_summary() {
    local TOTAL=${#SERVICES[@]}
    local ACTIVE=0
    local FAILED=0

    for SERVICE_INFO in "${SERVICES[@]}"; do
        SERVICE=$(echo $SERVICE_INFO | cut -d':' -f1)
        if systemctl is-active --quiet $SERVICE 2>/dev/null; then
            ACTIVE=$((ACTIVE + 1))
        else
            FAILED=$((FAILED + 1))
        fi
    done

    echo "$(date '+%Y-%m-%d %H:%M:%S') | 📊 Status: $ACTIVE/$TOTAL layanan aktif" >> $LOG

    if [ $FAILED -gt 0 ]; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') | 🚨 $FAILED layanan bermasalah!" >> $LOG
    fi
}

# ============================================
# MAIN - Jalankan semua pengecekan
# ============================================

# Header log setiap pengecekan
echo "$(date '+%Y-%m-%d %H:%M:%S') | ========== Health Check ==========" >> $LOG

# Cek semua service
RESTART_COUNT=0
FAIL_COUNT=0

for SERVICE_INFO in "${SERVICES[@]}"; do
    SERVICE=$(echo $SERVICE_INFO | cut -d':' -f1)
    DISPLAY=$(echo $SERVICE_INFO | cut -d':' -f2)
    PORT=$(echo $SERVICE_INFO | cut -d':' -f3)

    check_and_restart "$SERVICE" "$DISPLAY" "$PORT"
    STATUS=$?

    if [ $STATUS -eq 0 ] && ! systemctl is-active --quiet $SERVICE 2>/dev/null; then
        RESTART_COUNT=$((RESTART_COUNT + 1))
    elif [ $STATUS -ne 0 ]; then
        FAIL_COUNT=$((FAIL_COUNT + 1))
    fi
done

# Cek resource sistem
check_resources

# Generate ringkasan
generate_summary

# Footer log
echo "$(date '+%Y-%m-%d %H:%M:%S') | =================================" >> $LOG
