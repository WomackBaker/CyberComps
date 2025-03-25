#!/usr/bin/env bash

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

# Optionally test before installing
# ./src/nethogs

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

# Final check
nethogs
