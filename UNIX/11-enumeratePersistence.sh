#!/usr/bin/env bash
#

cmd_pattern='(curl|wget|bash|sh|zsh|mkfifo|python|perl|ruby|nc|netcat)'
ip_pattern='([0-9]{1,3}[.]){3}[0-9]{1,3}'

possible_backdoors() {
    local file="$1"
    # Ensure the file is readable before processing
    if [ -r "$file" ]; then
        awk -v cmd="$cmd_pattern" -v ip="$ip_pattern" '
            $0 ~ cmd && $0 ~ ip {
                print FILENAME " contains suspicious patterns."
                exit 0
            }
        ' "$file"
    fi
}

directories=(
    /home/
    /root/
    /var/tmp/
    /var/www/
    /tmp/
)

for d in "${directories[@]}"; do
    if [ -d "$d" ]; then
        find "$d" -type f 2>/dev/null | while read -r file; do
            possible_backdoors "$file"
        done
    fi
done
