#!/usr/bin/env bash
#
# 01-setupInstallHarden.sh (FreeBSD version)
# Usage: bash 01-setupInstallHarden.sh <port1> <port2> ...
# Example: bash 01-setupInstallHarden.sh 80 443 8080

# Ensure the script is run as root
if [ "$(whoami)" != "root" ]; then
    echo "Script must be run as root."
    exit 1
fi

# Require at least one port argument
if [ "$#" -lt 1 ]; then
    echo "Usage: bash 01-setupInstallHarden.sh <port1> <port2> ..."
    echo "Please specify at least one port."
    exit 1
fi

echo "Ports to be allowed through the firewall (PF, IPv4 only):"
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

#######################################
# OS Detection & Package Installation
#######################################

echo "FreeBSD detected. Updating and installing necessary packages..."
pkg update -f
pkg upgrade -y
pkg install -y git socat fail2ban zip htop

# Enable and start fail2ban if available
sysrc fail2ban_enable="YES" 2>/dev/null
service fail2ban start 2>/dev/null || echo "fail2ban may need further configuration."

#######################################
# Create initial backups
#######################################
echo "Creating backups..."
mkdir -p /backup/initial
cp -r /etc /backup/initial/etc
cp -r /home /backup/initial/home
cp -r /bin /backup/initial/bin
cp -r /usr/bin /backup/initial/usr/bin

#######################################
# Set up PF Firewall
#######################################
echo "Setting up PF firewall rules..."

# Check for an existing PF configuration; if present, back it up
if [ -f /etc/pf.conf ]; then
    echo "Existing PF configuration found. Backing up to /etc/pf.conf.bak..."
    cp /etc/pf.conf /etc/pf.conf.bak
else
    echo "No existing PF configuration found. Creating a new one."
fi


allowed_ports=(22 )
for port in "$@"; do
    allowed_ports+=("$port")
done

# Remove duplicate ports and format them as a comma-separated list
unique_ports=($(echo "${allowed_ports[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' '))
ports_pf=$(echo "${unique_ports[@]}" | tr ' ' ',' | sed 's/^,//; s/,$//')

# Generate a new PF configuration
cat <<EOF > /tmp/pf.conf.new
# PF configuration generated by 01-setupInstallHarden.sh
set skip on lo
block in all
pass out all
pass in proto tcp from any to any port { $ports_pf } keep state
EOF

# Install the new PF configuration
cp /tmp/pf.conf.new /etc/pf.conf

# Enable PF and load the new configuration
sysrc pf_enable="YES"
pfctl -f /etc/pf.conf
pfctl -e 2>/dev/null

echo "PF has been configured with allowed ports: { $ports_pf }"
pfctl -s info
pfctl -s rules

#######################################
# Start Honey Pot and run auxiliary script
#######################################
echo "Starting Honey Pot on port 2222..."
if [ -x "$HOME/Linux/linux-utility/overwriteBackdoor.sh" ]; then
    /usr/local/bin/bash "$HOME/Linux/linux-utility/overwriteBackdoor.sh"
else
    echo "Warning: $HOME/Linux/linux-utility/overwriteBackdoor.sh not found or not executable."
fi

#######################################
# Hash sensitive files
#######################################
echo "Hashing sensitive files..."
# On FreeBSD, password details are in /etc/master.passwd (instead of /etc/shadow)
master_passwd_hash=$(sha256 -q /etc/master.passwd 2>/dev/null)
passwd_hash=$(sha256 -q /etc/passwd 2>/dev/null)

mkdir -p "$HOME/Linux/linux-utility" 2>/dev/null
{
    echo "master_passwd_hash: $master_passwd_hash"
    echo "passwd_hash: $passwd_hash"
} >> "$HOME/Linux/linux-utility/hashes.txt"

#######################################
# List enabled services (rc.d)
#######################################
echo "Listing enabled services..."
service -e > "$HOME/Linux/linux-utility/services.txt"

#######################################
# Ensure correct permissions on password files
#######################################
echo "Ensuring /etc/passwd and /etc/master.passwd have correct ownership and permissions..."
chown root:wheel /etc/passwd
chmod 644 /etc/passwd

chown root:wheel /etc/master.passwd
chmod 600 /etc/master.passwd

#######################################
# Remove any NOPASSWD tokens from sudoers files
#######################################
echo "Checking for any NOPASSWD entries in sudoers..."
sudoers_files=(/etc/sudoers)
if [ -d /etc/sudoers.d ]; then
    sudoers_files+=(/etc/sudoers.d/*)
fi

for file in "${sudoers_files[@]}"; do
    [ -f "$file" ] || continue
    if grep -Eq '^[^#]*NOPASSWD:' "$file"; then
        echo "Found NOPASSWD in $file. Removing it..."
        sed -i '' 's/NOPASSWD:[[:space:]]*//g' "$file"
    else
        echo "No active NOPASSWD lines found in $file."
    fi
done

echo "********* DONE ************"
