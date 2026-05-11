#!/bin/bash
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

DOMAIN="farahamimah.net"
HOSTNAME="server"

echo -e "${YELLOW}[MAIL] Memulai instalasi Mail Server...${NC}"

# Hapus exim4 jika ada
apt remove --purge exim4* -y
apt autoremove -y

# Set hostname
echo "$HOSTNAME.$DOMAIN" > /etc/hostname
hostnamectl set-hostname $HOSTNAME.$DOMAIN
sed -i "s/127.0.1.1.*/127.0.1.1 $HOSTNAME.$DOMAIN $HOSTNAME/" /etc/hosts

# Pre-konfigurasi Postfix
echo "postfix postfix/mailname string $DOMAIN" | debconf-set-selections
echo "postfix postfix/main_mailer_type string 'Internet Site'" | debconf-set-selections

# Install Postfix + Dovecot
apt install -y postfix
apt install -y dovecot-core dovecot-imapd dovecot-pop3d
apt install -y mailutils
echo -e "${GREEN}[MAIL] Package terinstall${NC}"

# Konfigurasi Postfix
postconf -e "home_mailbox = Maildir/"
postconf -e "mydestination = $HOSTNAME.$DOMAIN, $DOMAIN, localhost"
postconf -e "mynetworks = 127.0.0.0/8 192.168.1.0/24"
postconf -e "inet_interfaces = all"
postconf -e "inet_protocols = all"

# Konfigurasi Dovecot
sed -i 's/#mail_location =/mail_location = maildir:~\/Maildir/' \
    /etc/dovecot/conf.d/10-mail.conf
sed -i 's/#disable_plaintext_auth = yes/disable_plaintext_auth = no/' \
    /etc/dovecot/conf.d/10-auth.conf
echo -e "${GREEN}[MAIL] Konfigurasi Dovecot selesai${NC}"

# Buat user email test
if ! id "mailuser" &>/dev/null; then
    useradd -m -s /bin/bash mailuser
    echo "mailuser:Mail1234!" | chpasswd
    echo -e "${GREEN}[MAIL] User mailuser dibuat${NC}"
fi

# Buat Maildir
mkdir -p /home/mailuser/Maildir/{cur,new,tmp}
chown -R mailuser:mailuser /home/mailuser/Maildir

# Restart services
systemctl restart postfix
systemctl enable postfix
systemctl restart dovecot
systemctl enable dovecot

# Verifikasi
POSTFIX_OK=false
DOVECOT_OK=false
systemctl is-active --quiet postfix && POSTFIX_OK=true
systemctl is-active --quiet dovecot && DOVECOT_OK=true

if $POSTFIX_OK && $DOVECOT_OK; then
    echo -e "${GREEN}[MAIL] ✅ Mail Server berhasil dikonfigurasi!${NC}"
    echo -e "${GREEN}[MAIL] Postfix (SMTP)      : AKTIF${NC}"
    echo -e "${GREEN}[MAIL] Dovecot (IMAP/POP3) : AKTIF${NC}"
    echo -e "${GREEN}[MAIL] User test: mailuser / Mail1234!${NC}"
    echo -e "${GREEN}[MAIL] Test: echo 'test' | mail -s 'Test' mailuser@$DOMAIN${NC}"
else
    echo -e "${RED}[MAIL] ❌ Cek log: journalctl -xe${NC}"
fi

echo -e "${GREEN}[MAIL] Instalasi selesai!${NC}"
