#!/bin/bash

# Will continiously kill any reverse shells.

while true; do
    ps -ef | grep -E 'nc|netcat|bash|sh|zsh|mkfifo|python|perl|ruby|wget|curl' | while read -r line; do
        if echo "$line" | grep -qE '([0-9]{1,3}\.){3}[0-9]{1,3}.*[0-9]+'; then
            pid=$(echo "$line" | awk '{print $2}')
            kill -9 "$pid"
        fi
    done
    sleep 10
done
