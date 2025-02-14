#!/usr/bin/env bash

SERVICE_LIST_FILE="root/Linux/linux-utility/services.txt"
LOG_FILE="root/Linux/script_log.txt"

# If services.txt doesn't exist, exit
if [[ ! -f "$SERVICE_LIST_FILE" ]]; then
  echo "ERROR: $SERVICE_LIST_FILE not found. Cannot verify which services to keep."
  exit 1
fi

# Grab currently running services
running_services=$(systemctl list-units --type=service --state=running --no-legend --no-pager | awk '{print $1}')

# Iterate over the running services
for svc in $running_services; do

  # Check if this service is listed in services.txt
  # grep -qx checks for an exact match on a line
  if ! grep -qx "$svc" "$SERVICE_LIST_FILE"; then
    # Not in services.txt => stop/kill this service
    systemctl stop "$svc" 2>/dev/null

    # Log to script_log.txt
    echo "$(date): Killed service $svc" >> "$LOG_FILE"
    echo "Killed service $svc"
  fi
done

echo "Done. Any unlisted services have been stopped, and kills logged to $LOG_FILE."