#!/usr/bin/env bash

# Ensure the script is run as root.
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root."
  exit 1
fi

echo "Erasing all user crontabs..."
for user in $(cut -d: -f1 /etc/passwd); do
  crontab -r -u "$user" 2>/dev/null
done

# Patterns to detect suspicious commands and IP addresses.
cmd_pattern='(curl|wget|bash|sh|zsh|mkfifo|python|perl|ruby|nc|netcat)'
ip_pattern='([0-9]{1,3}[.]){3}[0-9]{1,3}'

remove_suspicious_lines() {
    local file=$1
    # Make a backup of the file
    cp "$file" "$file.bak"
    # Remove lines containing both a suspicious command and an IP address.
    awk -v cmd="$cmd_pattern" -v ip="$ip_pattern" '{
        if ($0 ~ cmd && $0 ~ ip)
            next;
        print;
    }' "$file.bak" > "$file"
    rm "$file.bak"
}

# Clean /etc/crontab if it exists.
if [ -f /etc/crontab ]; then
    remove_suspicious_lines /etc/crontab
fi

# Clean files in /etc/cron.d if the directory exists.
if [ -d /etc/cron.d ]; then
    find /etc/cron.d/ -type f | while read -r file; do
        remove_suspicious_lines "$file"
    done
fi

# Clean files in cron daily/hourly/monthly/weekly directories if they exist.
for dir in cron.daily cron.hourly cron.monthly cron.weekly; do
    if [ -d "/etc/$dir" ]; then
        find "/etc/$dir" -type f | while read -r file; do
            remove_suspicious_lines "$file"
        done
    fi
done

echo "Cron cleanup completed."
