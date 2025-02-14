#!/bin/bash

# Remove nc, gcc and other compilers
rm `which nc` `which wget` `which gcc` `which cmake` 2>/dev/null

# red team backdoor
cat << 'EOF' > /bin/redd
#!/bin/bash
echo "Caught one boys!" >> /root/Linux/script_log.txt
ri(){
    echo -n "root@$HOSTNAME:$HOME# "
    read i; if [ -n "$i" ]; then
      echo "-bash: $i: command not found"
      echo "$(date +"%A %r") -- $i" >> /root/Linux/script_log.txt
    fi; ri
}
trap "ri" SIGINT SIGTSTP exit; ri
EOF

chmod +x /bin/redd
touch /root/Linux/script_log.txt
chmod 722 /root/Linux/script_log.txt

# Create a systemd socket to listen on port 2222
cat << 'EOF' > /etc/systemd/system/redd.socket
[Unit]
Description=Redd Service

[Socket]
ListenStream=2222
Accept=yes

[Install]
WantedBy=sockets.target
EOF

# Create the systemd service that spawns the backdoor for each connection
cat << 'EOF' > /etc/systemd/system/redd@.service
[Unit]
Description=Redd Service

[Service]
User=root
ExecStart=/bin/redd
StandardInput=socket
EOF

# Reload systemd units and enable the socket
systemctl daemon-reload
systemctl enable --now redd.socket