#! /bin/bash

# Script must be run as root
if [ "$(whoami)" != "root" ]; then
    echo "This script must be run as root."
    exit 1
fi

# Update and install prerequisites
apt update
apt install -y gpg apt-transport-https software-properties-common

# Install Git, Nmap, Net-tools, Curl, Wget, Flameshot, Terminator, LibreOffice
apt install -y git nmap net-tools curl wget flameshot terminator libreoffice

# Download Microsoft GPG key and add it (for VS Code)
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
install -o root -g root -m 644 packages.microsoft.gpg /usr/share/keyrings/
rm packages.microsoft.gpg

# Add the VS Code repository
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/vscode stable main" \
    > /etc/apt/sources.list.d/vscode.list

# Install VS Code
apt update
apt install -y code

echo "All done! Git, Nmap, Net-tools, Curl, Wget, Flameshot, Terminator, LibreOffice, and VS Code have been installed successfully."
