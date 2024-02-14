#!/bin/bash

# Install snoopy if it is not already installed, and will automatically get snoopy log files.

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

sudo tail -f "$SNOOPY_LOG_FILE" | grep snoopy | grep -vE "grep -qE|grep -qx|grep -qw|pkillBash.sh|ensureCorrectUsers.sh|grep -E (nc|netcat|bash|sh|zsh|mkfifo|python|perl|ruby|wget|curl)"
