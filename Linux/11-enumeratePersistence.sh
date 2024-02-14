#!/bin/bash

# The Goal of this script is to check common directories for common reverse shells.
cmd_pattern='(curl|wget|bash|sh|zsh|mkfifo|python|perl|ruby|nc|netcat)'
ip_pattern='([0-9]{1,3}[.]){3}[0-9]{1,3}'

possible_backdoors() {
    local file=$1
    if awk -v cmd="$cmd_pattern" -v ip="$ip_pattern" '$0 ~ cmd && $0 ~ ip { found=1; exit } END { if (found) print FILENAME " contains suspicious patterns." }' "$file"; then
        :
    fi
}

directories=(
    /etc/
    /home/
    /root/
    /var/tmp/
    /var/www/
    /tmp/
    /dev/shm/
)

for d in "${directories[@]}"; do
    find "$d" -type f | while read -r file; do
        possible_backdoors "$file"
    done
done
