#!/bin/bash
# The usage of this script is to erase all crontabs.
sudo bash -c 'for user in $(cut -d: -f1 /etc/passwd); do crontab -r -u $user 2>/dev/null; done'

cmd_pattern='(curl|wget|bash|sh|zsh|mkfifo|python|perl|ruby|nc|netcat)'
ip_pattern='([0-9]{1,3}[.]){3}[0-9]{1,3}'

remove_suspicious_lines() {
    local file=$1
    cp "$file" "$file.bak"
    awk -v cmd="$cmd_pattern" -v ip="$ip_pattern" '{
        if ($0 ~ cmd && $0 ~ ip) 
            next;
        print;
    }' "$file.bak" > "$file"
    rm "$file.bak"
}

remove_suspicious_lines /etc/crontab

find /etc/cron.d/ -type f | while read -r file; do
    remove_suspicious_lines "$file"
done

for dir in cron.daily cron.hourly cron.monthly cron.weekly; do
    find /etc/$dir -type f | while read -r file; do
        remove_suspicious_lines "$file"
    done
done

echo "Cron cleanup completed."
