#!/bin/bash

# Setup by installing required programs like dependencies, git, fail2ban, and ufw, configure
# what is necessary, and do some basic hardening.
# Usage: bash 01-setupInstallHarden.sh <port1> <port2> ...
# Example: bash 01-setupInstallHarden.sh 22 80 443 8080

if [ $(whoami) != "root" ]; then
    echo "Script must be run as root."
    exit 1
fi

if [ "$#" -lt 1 ]; then
    echo "Usage: bash 01-setupInstallHarden.sh <port1> <port2> ..."
    echo "Please specify at least one port."
    exit 1
fi

echo "Ports to be allowed through UFW:"
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
    # Some prefer to run both dnf and yum if symlinks differ, but typically dnf is enough
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
# Set up UFW
##############################
echo "Setting up UFW..."
echo "Disabling UFW temporarily for configuration..."
sudo ufw disable

sudo ufw --force reset

sudo ufw default deny incoming
sudo ufw default allow outgoing

for port in "$@"; do
    echo "Allowing port $port through UFW..."
    sudo ufw allow "$port"
done

# Always allow 22 in case we need SSH
sudo ufw allow 22
echo "Port 22 opened for SSH."

sudo ufw --force enable
echo "UFW has been configured and re-enabled."

sudo ufw status verbose

shadow_hash=$(sha256sum /etc/shadow | awk '{ print $1 }')
passwd_hash=$(sha256sum /etc/passwd | awk '{ print $1 }')

echo "shadow_hash: $shadow_hash" >> ./linux-utility/hashes.txt
echo "passwd_hash: $passwd_hash" >> ./linux-utility/hashes.txt

systemctl list-units --type=service --state=running --no-legend --no-pager \
  | awk '{print $1}' \
  >> ./linux-utility/services.txt

### FOR DOCKER ONLY ###
#service --status-all 2>/dev/null | grep '\[ + \]' | awk '{print $4}' >> ./linux-utility/services.txt



echo "********* DONE ************"
