#!/bin/bash

# 01-setupInstallHarden.sh
# Usage: bash 01-setupInstallHarden.sh <port1> <port2> ...
# Example: bash 01-setupInstallHarden.sh 22 80 443 8080
#
# This script:
#   - Installs common packages (fail2ban, ufw, etc.)
#   - Backs up certain directories
#   - Configures UFW to deny everything incoming by default and allow outgoing
#   - Allows specific ports (IPv4 only, since IPv6 is disabled below)

if [ $(whoami) != "root" ]; then
    echo "Script must be run as root."
    exit 1
fi

if [ "$#" -lt 1 ]; then
    echo "Usage: bash 01-setupInstallHarden.sh <port1> <port2> ..."
    echo "Please specify at least one port."
    exit 1
fi

echo "Ports to be allowed through UFW (IPv4 only, IPv6 is disabled):"
for port in "$@"; do
    echo "- $port"
done

read -r -p "Do you want to proceed with the above ports? (y/n): " response
if [[ "$response" =~ ^[Yy]$ ]]; then
    echo "Proceeding with the setup..."
else
    echo "Aborting."
    exit 0
fi

# Example call to another script (if you need it)
# ./getAllUsers.sh

# Grab the line starting with 'ID=' in /etc/os-release
id_line=$(grep '^ID=' /etc/os-release)
operatingSystem=$(echo "$id_line" | cut -d'=' -f2 | tr -d '"')

if [ -z "$operatingSystem" ]; then
    echo "The ID= line was not found or is empty in /etc/os-release."
else
    echo "Detected ID (Operating System): $operatingSystem"
fi

#######################################
# Debian/Ubuntu
#######################################
if [ "$operatingSystem" = "debian" ] || [ "$operatingSystem" = "ubuntu" ]; then
    echo "Debian/Ubuntu-based system detected, using apt."

    sudo apt update -y
    sudo apt upgrade -y

    sudo apt install -y rsyslog git socat fail2ban zip net-tools htop e2fsprogs ufw

    # Enable and start fail2ban
    sudo systemctl enable fail2ban
    sudo systemctl start fail2ban

#######################################
# CentOS/Rocky/Fedora
#######################################
elif [ "$operatingSystem" = "centos" ] || [ "$operatingSystem" = "rocky" ] || [ "$operatingSystem" = "fedora" ]; then
    echo "RHEL-based system detected ($operatingSystem). Using dnf/yum."

    # Update
    sudo dnf update -y
    sudo yum update -y || true  # Non-fatal if yum doesn't exist on some systems

    # For CentOS or Rocky, install EPEL:
    if [ "$operatingSystem" != "fedora" ]; then
      sudo dnf install -y epel-release
    fi

    # Common packages across RHEL-based:
    sudo dnf install -y git socat fail2ban zip net-tools htop e2fsprogs ufw

    # Enable and start fail2ban
    sudo systemctl enable fail2ban
    sudo systemctl start fail2ban

else
    echo "Unsupported or unrecognized OS (ID=$operatingSystem)."
    echo "Please extend the script or install packages manually."
    exit 1
fi

##############################
# Create initial backups
##############################
echo "Creating backups..."
sudo mkdir -p /backup/initial

# Backup /etc
cp -r /etc /backup/initial/etc
# Backup /home
cp -r /home /backup/initial/home
# Backup /bin
cp -r /bin /backup/initial/bin
# Backup /usr/bin
cp -r /usr/bin /backup/initial/usr/bin

##############################
# Disable IPv6 in UFW
##############################
# This ensures that UFW does not open any IPv6 ports.
if [ -f /etc/default/ufw ]; then
    echo "Disabling IPv6 in UFW (/etc/default/ufw)..."
    sed -i 's/^IPV6=yes/IPV6=no/' /etc/default/ufw
fi

##############################
# Set up UFW
##############################
echo "Setting up UFW..."
echo "Disabling UFW temporarily for configuration..."
sudo ufw disable

sudo ufw --force reset

sudo ufw default deny incoming
sudo ufw default allow outgoing

for port in "$@"; do
    echo "Allowing port $port (IPv4 only) through UFW..."
    sudo ufw allow "$port"
done

# Always allow 22 in case we need SSH
sudo ufw allow 22
echo "Port 22 opened for SSH."

echo "Starting Honey Pot on port 2222..."
sudo ufw allow 2222
bash ~/Linux/linux-utility/overwriteBackdoor.sh

sudo ufw --force enable
echo "UFW has been configured and re-enabled."

echo "UFW status:"
sudo ufw status verbose

##############################
# Hash the shadow and passwd files
##############################
shadow_hash=$(sha256sum /etc/shadow | awk '{ print $1 }')
passwd_hash=$(sha256sum /etc/passwd | awk '{ print $1 }')

mkdir -p "$HOME/Linux/linux-utility" 2>/dev/null
echo "shadow_hash: $shadow_hash" >> "$HOME/Linux/linux-utility/hashes.txt"
echo "passwd_hash: $passwd_hash" >> "$HOME/Linux/linux-utility/hashes.txt"

##############################
# List running services
##############################
systemctl list-units --type=service --state=running --no-legend --no-pager \
  | awk '{print $1}' \
  >> "$HOME/Linux/linux-utility/services.txt"

##################################
# Ensure /etc/passwd & /etc/shadow
# have correct permissions
##################################
echo "Ensuring /etc/passwd and /etc/shadow have correct ownership and permissions..."
chown root:root /etc/passwd
chmod 644 /etc/passwd

chown root:root /etc/shadow
chmod 600 /etc/shadow

##################################
# Remove the 'NOPASSWD:' token 
# from sudoers (instead of commenting or deleting the line)
##################################
echo "Checking for any NOPASSWD entries in sudoers..."

# List of sudoers files to scan
sudoers_files=(/etc/sudoers)
if [ -d /etc/sudoers.d ]; then
  sudoers_files+=(/etc/sudoers.d/*)
fi

for file in "${sudoers_files[@]}"; do
  # Skip if it's not a regular file
  [ -f "$file" ] || continue
  
  if grep -Eq '^[^#]*NOPASSWD:' "$file"; then
    echo "Found NOPASSWD in $file. Removing it..."
    sed -i 's/NOPASSWD:[[:space:]]*//g' "$file"
  else
    echo "No active NOPASSWD lines found in $file."
  fi
done

echo "********* DONE ************"
