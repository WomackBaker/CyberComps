#!/usr/bin/env bash
#
# Name: ccdc_network_enumeration.sh
# Description: Perform an Nmap-based network enumeration and store results in a nicely formatted .txt file.
# Usage: ./ccdc_network_enumeration.sh <target>
# Example: ./ccdc_network_enumeration.sh 192.168.1.0/24

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <target>"
  echo "Example: $0 10.0.0.0/24"
  exit 1
fi

TARGET="$1"
OUTPUT_FILE="scan_results.txt"

########################################
# 1) Ping Sweep (Host Discovery)
########################################
echo "[+] Performing ping sweep on $TARGET ..."
nmap -sn "$TARGET" -oN live_hosts.tmp > /dev/null 2>&1

# Extract only IP addresses for live hosts
LIVE_HOSTS=$(grep -oP '(?<=for )(\d{1,3}\.){3}\d{1,3}' live_hosts.tmp)

########################################
# 2) Write Header to Output
########################################
cat << 'EOF' > "$OUTPUT_FILE"
  ____ ____  ____ 
 / ___/ ___||  _ \
 \___ \___ \| | | |
  ___) |__) | |_| |
 |____/____/|____/

CCDC Network Enumeration Script
EOF

echo "======================================================" >> "$OUTPUT_FILE"
echo "Target: $TARGET" >> "$OUTPUT_FILE"
echo "Scan Started: $(date)" >> "$OUTPUT_FILE"
echo "======================================================" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

########################################
# 3) List Live Hosts
########################################
echo "Live Hosts Found:" >> "$OUTPUT_FILE"
if [ -z "$LIVE_HOSTS" ]; then
  echo "   None (No live hosts discovered via ping sweep)" >> "$OUTPUT_FILE"
else
  for HOST in $LIVE_HOSTS; do
    echo "   - $HOST" >> "$OUTPUT_FILE"
  done
fi
echo "" >> "$OUTPUT_FILE"

########################################
# 4) Detailed Scans for Each Live Host
########################################
if [ -n "$LIVE_HOSTS" ]; then
  echo "[+] Performing deeper scans on discovered hosts..."
  for HOST in $LIVE_HOSTS; do
    
    ########################################
    # 4a) Host Scan
    ########################################
    echo "[+] Scanning host: $HOST"
    nmap -p- -sV -sC -O -Pn "$HOST" -oN host_scan.tmp > /dev/null 2>&1
    
    echo "------------------------------------------------------" >> "$OUTPUT_FILE"
    echo "Host: $HOST" >> "$OUTPUT_FILE"
    echo "------------------------------------------------------" >> "$OUTPUT_FILE"
    
    # Append the full raw Nmap output for reference
    cat host_scan.tmp >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
    
    ########################################
    # 4b) Web Server Detection
    ########################################
    # We'll look for open TCP lines indicating HTTP/HTTPS or known web services
    WEB_LINES=$(grep -E '^([0-9]+)/tcp\s+open' host_scan.tmp | grep -Ei '(http|ssl/http|https|IIS|apache|nginx|tomcat)')

    if [ -n "$WEB_LINES" ]; then
      echo "   Possible Web Server(s) Detected:" >> "$OUTPUT_FILE"
      while IFS= read -r WLINE; do
        # Example line: "80/tcp open  http    Apache httpd 2.4.6 ((CentOS))"
        PORT=$(echo "$WLINE" | awk -F'/' '{print $1}')
        # We remove the first three tokens with cut to skip "open" and the immediate service name, 
        # leaving the server product/version in the remainder
        SERVER_INFO=$(echo "$WLINE" | cut -d ' ' -f 4-)
        echo "      - Port $PORT: $SERVER_INFO" >> "$OUTPUT_FILE"
      done <<< "$WEB_LINES"
      echo "" >> "$OUTPUT_FILE"
    fi

    echo "" >> "$OUTPUT_FILE"
    
  done
fi

########################################
# 5) Cleanup & Footer
########################################
rm -f live_hosts.tmp host_scan.tmp

echo "======================================================" >> "$OUTPUT_FILE"
echo "Scan Completed: $(date)" >> "$OUTPUT_FILE"
echo "Results saved to $OUTPUT_FILE" >> "$OUTPUT_FILE"
echo "======================================================" >> "$OUTPUT_FILE"

echo "[+] Enumeration complete! Results stored in: $OUTPUT_FILE"
