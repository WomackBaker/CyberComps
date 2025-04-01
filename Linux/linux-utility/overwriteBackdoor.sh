#!/bin/bash

# Create the logging directory and file
mkdir -p /root/Linux
touch /root/Linux/script_log.txt
chmod 722 /root/Linux/script_log.txt

# Create the fake shell script that logs user input
cat << 'EOF' > /bin/redd
#!/bin/bash
echo "Caught one boys!" >> /root/Linux/script_log.txt

ri(){
    echo -n "root@$HOSTNAME:$HOME# "
    read i
    if [ -n "$i" ]; then
        echo "-bash: $i: command not found"
        echo "$(date +"%A %r") -- $i" >> /root/Linux/script_log.txt
    fi
    ri
}

trap "ri" SIGINT SIGTSTP EXIT
ri
EOF

chmod +x /bin/redd

# Create a wrapper script to log the connecting IP (no banning)
cat << 'EOF' > /bin/redd-log
#!/bin/bash
INSTANCE_NAME="$1"

IP="$(echo "$INSTANCE_NAME" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' | tail -1)"

if [[ "$IP" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]] && [ "$IP" != "127.0.0.1" ]]; then
    echo "$(date +"%Y-%m-%d %H:%M:%S") -- Connection from $IP" >> /root/Linux/script_log.txt
fi

exec /bin/redd
EOF

chmod +x /bin/redd-log

# Create the systemd socket unit
cat << 'EOF' > /etc/systemd/system/redd.socket
[Unit]
Description=Redd Service Socket

[Socket]
ListenStream=2222
Accept=yes

[Install]
WantedBy=sockets.target
EOF

# Create the systemd service unit
cat << 'EOF' > /etc/systemd/system/redd@.service
[Unit]
Description=Redd Service Instance

[Service]
User=root
ExecStart=/bin/redd-log %i
StandardInput=socket
EOF

# Reload systemd and enable the socket
systemctl daemon-reload
systemctl enable --now redd.socket
