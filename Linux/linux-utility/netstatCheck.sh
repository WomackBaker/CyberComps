#!/bin/bash

NETSTAT_FILE="/root/Linux/linux-utility/netstat.txt"
TEMP_FILE="/root/Linux/linux-utility/netstat_temp.txt"
LOG_FILE="/root/Linux/script_log.txt"

# Function to extract process ID, port, and IP from netstat
function get_netstat_info() {
    # Get LISTEN and ESTABLISHED connections with process IDs
    netstat -tunlp 2>/dev/null | awk 'NR>2 {print $4, $5, $7}' | sort | uniq
}

# Ensure netstat.txt exists
if [ ! -f "$NETSTAT_FILE" ]; then
    echo "Creating $NETSTAT_FILE..."
    get_netstat_info > "$NETSTAT_FILE"
fi

while true; do
    # Capture current netstat output
    get_netstat_info > "$TEMP_FILE"

    # Compare with previous data
    NEW_CONNECTIONS=$(comm -13 "$NETSTAT_FILE" "$TEMP_FILE")

    # If there are new connections, alert
    if [ ! -z "$NEW_CONNECTIONS" ]; then
        while IFS= read -r line; do
            IP_PORT=$(echo "$line" | awk '{print $1}')
            PROCESS_ID=$(echo "$line" | awk -F '/' '{print $2}')
            DATE=$(date "+%Y-%m-%d %H:%M:%S")
            ALERT="ALERT: New CONNECTION ($DATE) - PID: $PROCESS_ID, IP:Port: $IP_PORT"
            echo "$ALERT"
            echo "$ALERT" >> "$LOG_FILE"
        done <<< "$NEW_CONNECTIONS"
    fi

    # Update netstat.txt
    mv "$TEMP_FILE" "$NETSTAT_FILE"

    # Wait before rechecking
    sleep 5
done
