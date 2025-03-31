#!/bin/bash

# 01-setupInstallHarden.sh
# Usage: bash 01-setupInstallHarden.sh [-i] <port1> <port2> ...
# Example: bash 01-setupInstallHarden.sh -i 22 80 443 8080

if [ "$(whoami)" != "root" ]; then
    echo "Script must be run as root."
    exit 1
fi

INTERACTIVE=false

# Check for -i flag
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
    if [[ "$response" =~ ^[Yy]$ ]]; then
        echo "Proceeding with the setup..."
    else
        echo "Aborting."
        exit 0
    fi
else
    echo "Interactive mode (-i) enabled. Proceeding without confirmation."
fi

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

    sudo systemctl enable fail2ban
    sudo systemctl start fail2ban

#######################################
# CentOS/Rocky/Fedora
#######################################
elif [ "$operatingSystem" = "centos" ] || [ "$operatingSystem" = "rocky" ] || [ "$operatingSystem" = "fedora" ]; then
    echo "RHEL-based system detected ($operatingSystem). Using dnf/yum."
    sudo dnf update -y
    sudo yum update -y || true
    if [ "$operatingSystem" != "fedora" ]; then
        sudo dnf install -y epel-release
    fi
    sudo dnf install -y git socat fail2ban zip net-tools htop e2fsprogs ufw

    sudo systemctl enable fail2ban
    sudo systemctl start fail2ban

else
    echo "Unsupported or unrecognized OS (ID=$operatingSystem)."
    exit 1
fi

########################################
# Disable and remove other firewalls
########################################
echo "Disabling and removing other firewall services..."

# === FIREWALLD ===
if systemctl list-unit-files | grep -q firewalld.service; then
    echo "[+] Stopping and disabling firewalld..."
    systemctl stop firewalld
    systemctl disable firewalld
fi

echo "[+] Removing firewalld package..."
if command -v dnf &>/dev/null || command -v yum &>/dev/null; then
    dnf remove -y firewalld || yum remove -y firewalld
elif command -v apt &>/dev/null; then
    apt purge -y firewalld
fi

echo "[+] Deleting firewalld binaries..."
firewalld_bins=(/usr/sbin/firewalld /usr/bin/firewalld /sbin/firewalld /bin/firewalld /usr/lib/firewalld)
for path in "${firewalld_bins[@]}"; do
    if [ -e "$path" ]; then
        echo "    Removing: $path"
        rm -rf "$path"
    fi
done


# === NFTABLES ===
if systemctl list-unit-files | grep -q nftables.service; then
    echo "[+] Stopping and disabling nftables..."
    systemctl stop nftables
    systemctl disable nftables
fi

echo "[+] Removing nftables package..."
if command -v dnf &>/dev/null || command -v yum &>/dev/null; then
    dnf remove -y nftables || yum remove -y nftables
elif command -v apt &>/dev/null; then
    apt purge -y nftables
fi

echo "[+] Deleting nft binaries..."
nft_bins=(/usr/sbin/nft /usr/bin/nft /sbin/nft /bin/nft)
for path in "${nft_bins[@]}"; do
    if [ -e "$path" ]; then
        echo "    Removing: $path"
        rm -f "$path"
    fi
done


# === IPTABLES ===
if systemctl list-unit-files | grep -q iptables.service; then
    echo "[+] Stopping and disabling iptables..."
    systemctl stop iptables
    systemctl disable iptables
fi

echo "[+] Flushing iptables and ip6tables rules..."
iptables -F || true
ip6tables -F || true
rm -f /etc/iptables/rules.v4 /etc/iptables/rules.v6 2>/dev/null

echo "[+] Removing iptables package..."
if command -v dnf &>/dev/null || command -v yum &>/dev/null; then
    dnf remove -y iptables || yum remove -y iptables
elif command -v apt &>/dev/null; then
    apt purge -y iptables
fi

echo "[+] Deleting iptables binaries..."
iptables_bins=(/usr/sbin/iptables /usr/bin/iptables /sbin/iptables /bin/iptables /usr/sbin/ip6tables /usr/bin/ip6tables /sbin/ip6tables /bin/ip6tables)
for path in "${iptables_bins[@]}"; do
    if [ -e "$path" ]; then
        echo "    Removing: $path"
        rm -f "$path"
    fi
done

# Optional: Clean up alternatives system
alternatives --remove-all iptables 2>/dev/null || true
alternatives --remove-all firewalld 2>/dev/null || true
alternatives --remove-all nft 2>/dev/null || true
update-alternatives --remove-all iptables 2>/dev/null || true
update-alternatives --remove-all firewalld 2>/dev/null || true
update-alternatives --remove-all nft 2>/dev/null || true

##############################
# Create initial backups
##############################
echo "Creating backups..."
mkdir -p /backup/initial
cp -r /etc /backup/initial/etc
cp -r /home /backup/initial/home
cp -r /bin /backup/initial/bin
cp -r /usr/bin /backup/initial/usr/bin

##############################
# Disable IPv6 in UFW
##############################
if [ -f /etc/default/ufw ]; then
    echo "Disabling IPv6 in UFW (/etc/default/ufw)..."
    sed -i 's/^IPV6=yes/IPV6=no/' /etc/default/ufw
fi

##############################
# Set up UFW
##############################
echo "Setting up UFW..."
ufw disable
ufw --force reset
ufw default deny incoming
ufw default allow outgoing

for port in "$@"; do
    echo "Allowing port $port (IPv4 only) through UFW..."
    ufw allow "$port"
done

ufw allow 22
echo "Port 22 opened for SSH."

echo "Starting Honey Pot on port 2222..."
ufw allow 2222
bash ~/Linux/linux-utility/overwriteBackdoor.sh

ufw --force enable
echo "UFW has been configured and re-enabled."

echo "UFW status:"
ufw status verbose

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
# from sudoers
##################################
echo "Checking for any NOPASSWD entries in sudoers..."

sudoers_files=(/etc/sudoers)
if [ -d /etc/sudoers.d ]; then
  sudoers_files+=(/etc/sudoers.d/*)
fi
echo "==================================="
echo " SUIDER - SUID Exploit Finder Tool "
echo "==================================="

echo "[+] Looking for standard exploitable SUID binaries...."
r=$(find / -perm -u=s -type f 2>/dev/null | rev | cut -d'/' -f 1 | rev)


output=($r)
dict=(aria2c arp ash base32 base64 basenc bash busybox capsh cat chmod chown chroot column comm cp csh csplit curl cut dash date dd dialog diff dmsetup docker emacs env eqn expand expect find flock fmt fold gdb gimp grep gtester hd head hexdump highlight iconv install ionice ip jjs join jq jrunscript ksh ks ld.so less logsave look lwp-download lwp-request make more mv nano nice nl node nohup od openssl paste perl pg php pico pr python readelf restic rev rlwrap rpm rpmquery rsync run-parts rview rvim sed setarch shuf soelim sort ss ssh-keyscan start-stop-daemon stdbuf strace strings sysctl systemctl tac tail taskset tbl tclsh tee tftp time timeout troff ul unexpand uniq unshare update-alternatives uudecode uuencode view vim watch wget xargs xmodmap xxd xz zsh zsoelim)

result=()

for a in "${output[@]}"; do
    for b in "${dict[@]}"; do
        if [[ $a == "$b" ]]; then
            result+=( "$a" )
            break
        fi
    done
done

if [[ -z ${result[@]} ]]
then 
    echo "[-] Nothing Found!"

else

    echo '---------------------------------'
    echo " REMOVING SUID BIT FROM BINARIES"
    echo '---------------------------------'

    for i in "${result[@]}"
    do
        full_path=$(which "$i" 2>/dev/null)
        if [[ -n $full_path ]]; then
            echo "[+] Removing SUID bit from: $full_path"
            sudo chmod -s "$full_path"
        else
            echo "[-] Binary not found in PATH: $i"
        fi
    done
fi

for file in "${sudoers_files[@]}"; do
  [ -f "$file" ] || continue
  if grep -Eq '^[^#]*NOPASSWD:' "$file"; then
    echo "Found NOPASSWD in $file. Removing it..."
    sed -i 's/NOPASSWD:[[:space:]]*//g' "$file"
  else
    echo "No active NOPASSWD lines found in $file."
  fi
done

echo "********* DONE ************"
