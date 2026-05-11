#!/bin/bash
# ============================================
# SSH Server Hardening Script
# ============================================

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}[SSH] Memulai instalasi & hardening SSH Server...${NC}"

# Install OpenSSH
apt install -y openssh-server

# Backup konfigurasi asli
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup
echo -e "${GREEN}[SSH] Backup konfigurasi asli disimpan di sshd_config.backup${NC}"

# Konfigurasi SSH Hardening
cat > /etc/ssh/sshd_config << 'EOF'
# ============================================
# SSH Hardening Configuration
# Auto Server Provisioning - farahamimah.net
# ============================================

Port 22
Protocol 2
HostKey /etc/ssh/ssh_host_rsa_key
HostKey /etc/ssh/ssh_host_ecdsa_key
HostKey /etc/ssh/ssh_host_ed25519_key

# Autentikasi
LoginGraceTime 30
PermitRootLogin yes
StrictModes yes
MaxAuthTries 3
MaxSessions 5

# Keamanan
PubkeyAuthentication yes
PasswordAuthentication yes
PermitEmptyPasswords no
ChallengeResponseAuthentication no

# Fitur
X11Forwarding no
PrintMotd yes
AcceptEnv LANG LC_*
Subsystem sftp /usr/lib/openssh/sftp-server

# Logging
SyslogFacility AUTH
LogLevel VERBOSE

# Timeout
ClientAliveInterval 300
ClientAliveCountMax 2
EOF

# Buat pesan banner login
cat > /etc/ssh/banner.txt << 'EOF'
*******************************************
*   AUTO SERVER PROVISIONING             *
*   server.farahamimah.net               *
*   Authorized Access Only!              *
*******************************************
EOF

# Tambahkan banner ke sshd_config
echo "Banner /etc/ssh/banner.txt" >> /etc/ssh/sshd_config

# Restart SSH
systemctl restart ssh
systemctl enable ssh

# Verifikasi status
if systemctl is-active --quiet ssh; then
    echo -e "${GREEN}[SSH] ✅ SSH Server berhasil dikonfigurasi!${NC}"
    echo -e "${GREEN}[SSH] Status: AKTIF${NC}"
    systemctl status ssh --no-pager | grep "Active:"
else
    echo -e "${RED}[SSH] ❌ SSH Server gagal dijalankan!${NC}"
fi

echo -e "${GREEN}[SSH] Hardening selesai!${NC}"
