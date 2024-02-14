#!/bin/bash

# Setup by installing required programs like dependencies, git, fail2ban, and ufw, configure what is nessesary, and do some basic hardening.
# Usage bash 1setupInstallHarde.sh <port1> <port2> (bash 1setupInstallHarde.sh 22 80 443 8080)
if [ $(whoami) != "root" ]; then
    echo "Script must be run as root"
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


id_like_line=$(grep '^ID=' /etc/os-release)

operatingSystem=$(echo $id_like_line | cut -d'=' -f2 | tr -d '"')

if [ -z "$operatingSystem" ]; then
    echo "The ID_LIKE line was not found or is empty."
else
    echo "Operating System base: $operatingSystem"
fi

if [ "$operatingSystem" = "debian" ] || [ "$operatingSystem" = "ubuntu" ]; then
    echo "$operatingSystem detected, using apt"

    sudo apt update -y
    sudo apt upgrade -y
    sudo apt install rsyslog -y
    sudo apt install git -y
    sudo apt install socat -y
    sudo apt install fail2ban -y
    sudo apt install zip -y
    sudo apt install net-tools -y
    sudo apt install htop -y
    sudo apt install e2fsprogs -y
    sudo systemctl enable fail2ban
    sudo systemctl start fail2ban

    sudo apt install ufw -y

elif [ "$operatingSystem" = "centos" ]; then
    echo "CentOS detected, using yum"
    sudo dnf update -y
    sudo yum update -y
    sudo yum install -y epel-release
    sudo yum install git -y
    sudo yum install socat -y
    sudo yum install fail2ban -y
    sudo yum install zip -y
    sudo yum install net-tools -y
    sudo yum install htop -y
    sudo yum install e2fsprogs -y
    sudo systemctl enable fail2ban
    sudo systemctl start fail2ban

    sudo yum install ufw -y
fi

############################## BACKUPS
echo "Creating backups..."
sudo mkdir -p /backup/initial

############################## BACKUP /etc
cp -r /etc /backup/initial/etc

############################## BACKUP /home
cp -r /home /backup/initial/home

############################## BACKUP /bin
cp -r /bin /backup/initial/bin

############################## BACKUP /usr/bin
cp -r /usr/bin /backup/initial/usr/bin

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

sudo ufw --force enable
echo "UFW has been configured and re-enabled."

sudo ufw status verbose
