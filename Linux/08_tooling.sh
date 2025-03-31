#!/bin/bash

wget https://github.com/DominicBreuker/pspy/releases/download/v1.2.1/pspy64
chmod +x pspy64


echo "Installing Snoopy Logger..."
wget -O install-snoopy.sh https://github.com/a2o/snoopy/raw/install/install/install-snoopy.sh &&
chmod 755 install-snoopy.sh &&
sudo ./install-snoopy.sh stable
rm -rf install-snoopy*

get_snoopy_log_file() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        case "$ID" in
            centos)
                echo "/var/log/secure"
                ;;
            debian|ubuntu)
                echo "/var/log/auth.log"
                ;;
            *)
                echo "/var/log/messages"
                ;;
        esac
    else
        echo "Cannot determine OS or /etc/os-release not found!"
        exit 1
    fi
}

SNOOPY_LOG_FILE=$(get_snoopy_log_file)

echo "Tailing the Snoopy log file: $SNOOPY_LOG_FILE"

sudo tail -f "$SNOOPY_LOG_FILE" | grep snoopy | grep -vE "grep -qE|grep -qx|grep -qw|pkillBash.sh|serviceCheck.sh|sha256sum|hashes.txt|ensureCorrectUsers.sh|grep -E (nc|netcat|bash|sh|zsh|mkfifo|python|perl|ruby|wget|curl)"


# Ensure root
if [ "$(id -u)" -ne 0 ]; then
  echo "Script must be run as root."
  exit 1
fi

# Detect OS via /etc/os-release
if [ -f /etc/os-release ]; then
  . /etc/os-release
else
  echo "Cannot detect OS. Exiting."
  exit 1
fi

# Install dependencies based on OS
if command -v apt-get &>/dev/null; then
  apt-get update
  apt-get install -y build-essential libncurses5-dev libpcap-dev git
elif command -v yum &>/dev/null; then
  yum install -y gcc-c++ libpcap-devel.x86_64 libpcap.x86_64 ncurses-devel git
else
  echo "Unsupported package manager. Exiting."
  exit 1
fi

# Clone NetHogs
git clone https://github.com/raboof/nethogs
cd nethogs || exit 1

# Compile
make

# If Debian/Ubuntu, optionally use checkinstall
if [ "$ID" = "ubuntu" ] || [ "$ID" = "debian" ]; then
  apt-get install -y checkinstall
  # This creates a .deb that can be installed or removed easily
  checkinstall --pkgname=nethogs --maintainer="you@example.com" \
    --pkgversion="$(date +%Y%m%d%H%M)" -y make install
  dpkg -i nethogs*.deb
else
  # Otherwise, just install normally
  make install
fi

# Hash refresh
hash -r

# Path to the file you want to copy
SOURCE_FILE="AllPasswords.csv"

# Check if the file exists
if [[ ! -f "$SOURCE_FILE" ]]; then
    echo "Source file '$SOURCE_FILE' not found."
    exit 1
fi

# Loop through each home directory under /home
for dir in /home/*; do
    if [[ -d "$dir" ]]; then
        cp "$SOURCE_FILE" "$dir/"
        echo "Copied to $dir/"
    fi
done

# Also copy to root's home directory
cp "$SOURCE_FILE" /root/ && echo "Copied to /root/"


cd $HOME/ && git clone https://github.com/gerbsec/Nixarmor-But-Better.git && cd Nixarmor-But-Better && git checkout ccdc && sudo bash init.sh 

cp ./linux-utility/pspy.sh /usr/bin/local/pspy.sh
chmod +x /usr/bin/local/pspy.sh
echo "pspy.sh installed to /usr/bin/local/pspy.sh"

cp ./linux-utility/snoopy.sh /usr/bin/local/snoopy.sh
chmod +x /usr/bin/local/snoopy.sh
echo "snoopy.sh installed to /usr/bin/local/snoopy.sh"

cp ./linux-utility/ipban.sh /usr/bin/local/ipban.sh
chmod +x /usr/bin/local/ipban.sh
echo "ipban.sh installed to /usr/bin/local/ipban.sh"
