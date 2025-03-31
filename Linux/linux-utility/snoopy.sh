#!/bin/bash

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

sudo tail -f "$SNOOPY_LOG_FILE" | grep snoopy | grep -vE "grep -qE|grep -qx|grep -qw|pkillBash.sh|serviceCheck.sh|sha256sum|hashes.txt|ensureCorrectUsers.sh|grep -E (nc|netcat|bash|sh|zsh|mkfifo|python|perl|ruby|wget|curl)"
