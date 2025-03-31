#!/bin/bash

# 01-setupInstallHarden.sh
# Usage: bash 01-setupInstallHarden.sh [-i] <port1> <port2> ...
# Example: bash 01-setupInstallHarden.sh -i 22 80 443 8080

if [ "$(whoami)" != "root" ]; then
    echo "Script must be run as root."
    exit 1
fi

INTERACTIVE=false
if [ "$1" == "-i" ]; then
    INTERACTIVE=true
    shift
fi

if [ "$#" -lt 1 ]; then
    echo "Usage: bash 01-setupInstallHarden.sh [-i] <port1> <port2> ..."
    echo "Please specify at least one port."
    exit 1
fi

echo "Ports to be allowed through UFW (IPv4 only, IPv6 is disabled):"
for port in "$@"; do
    echo "- $port"
done

if [ "$INTERACTIVE" = false ]; then
    read -r -p "Do you want to proceed with the above ports? (y/n): " response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        echo "Aborting."
        exit 0
    fi
else
    echo "Interactive mode (-i) enabled. Proceeding without confirmation."
fi

operatingSystem=$(grep '^ID=' /etc/os-release | cut -d'=' -f2 | tr -d '"')
echo "Detected ID (Operating System): $operatingSystem"

if [[ "$operatingSystem" =~ ^(debian|ubuntu)$ ]]; then
    apt update -y && apt upgrade -y
    apt install -y rsyslog git socat fail2ban zip net-tools htop e2fsprogs ufw
elif [[ "$operatingSystem" =~ ^(centos|rocky|fedora)$ ]]; then
    dnf update -y || yum update -y || true
    [[ "$operatingSystem" != "fedora" ]] && dnf install -y epel-release
    dnf install -y git socat fail2ban zip net-tools htop e2fsprogs ufw
else
    echo "Unsupported or unrecognized OS (ID=$operatingSystem)."
    exit 1
fi

systemctl enable fail2ban
systemctl start fail2ban

##############################
# Backup
##############################
echo "Creating backups..."
mkdir -p /backup/initial
cp -r /etc /backup/initial/etc
cp -r /home /backup/initial/home
cp -r /bin /backup/initial/bin
cp -r /usr/bin /backup/initial/usr/bin

##############################
# UFW setup
##############################
[ -f /etc/default/ufw ] && sed -i 's/^IPV6=yes/IPV6=no/' /etc/default/ufw

ufw disable
ufw --force reset
ufw default deny incoming
ufw default allow outgoing

for port in "$@"; do
    ufw allow "$port"
done

ufw allow 22
ufw allow 2222

bash ~/Linux/linux-utility/overwriteBackdoor.sh

ufw --force enable
ufw status verbose

##############################
# Hash passwd and shadow
##############################
mkdir -p "$HOME/Linux/linux-utility"
echo "shadow_hash: $(sha256sum /etc/shadow | awk '{print $1}')" >> "$HOME/Linux/linux-utility/hashes.txt"
echo "passwd_hash: $(sha256sum /etc/passwd | awk '{print $1}')" >> "$HOME/Linux/linux-utility/hashes.txt"

##############################
# List services
##############################
systemctl list-units --type=service --state=running --no-legend --no-pager |
  awk '{print $1}' >> "$HOME/Linux/linux-utility/services.txt"

##############################
# Fix permissions
##############################
chown root:root /etc/passwd && chmod 644 /etc/passwd
chown root:root /etc/shadow && chmod 600 /etc/shadow

##############################
# Remove NOPASSWD from sudoers
##############################
echo "Checking sudoers for NOPASSWD entries..."
sudoers_files=(/etc/sudoers)
[ -d /etc/sudoers.d ] && sudoers_files+=(/etc/sudoers.d/*)
for file in "${sudoers_files[@]}"; do
  [ -f "$file" ] || continue
  if grep -Eq '^[^#]*NOPASSWD:' "$file"; then
    echo "Removing NOPASSWD from $file..."
    sed -i 's/NOPASSWD:[[:space:]]*//g' "$file"
  fi
done

echo "********* DONE ************"
