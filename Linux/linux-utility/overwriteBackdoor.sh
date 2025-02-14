#!/bin/bash

# red team backdoor (/bin/redd)
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

# Create a log file for the connections
mkdir -p /root/Linux
touch /root/Linux/script_log.txt
chmod 722 /root/Linux/script_log.txt

# --------------------
# WRAPPER SCRIPT that handles the ban before running /bin/redd
# --------------------
cat << 'EOF' > /bin/redd-ban
#!/bin/bash
# This script is used as ExecStart in our redd@.service
# to ban any non-localhost IP via ufw, then execute /bin/redd.

INSTANCE_NAME="$1"

# 1. Parse out the raw address part from something like "1.2.3.4:56789" or "[::1]:12345"
#    The sed command below will strip off the optional brackets and everything after the last colon.
IP=$(echo "$INSTANCE_NAME" | sed 's/^\(\[\?\([^]]*\)\]?\).*/\2/')

# 2. If not localhost, ban it
if [ "$IP" != "127.0.0.1" ] && [ "$IP" != "::1" ]; then
    echo "Banning IP: $IP" >> /root/Linux/script_log.txt
    ufw deny from "$IP" to any port 2222
fi

# 3. Finally, launch the real backdoor
exec /bin/redd
EOF

chmod +x /bin/redd-ban

# --------------------
# SYSTEMD UNITS
# --------------------

# Create a systemd socket to listen on port 2222
cat << 'EOF' > /etc/systemd/system/redd.socket
[Unit]
Description=Redd Service Socket

[Socket]
ListenStream=2222
Accept=yes

[Install]
WantedBy=sockets.target
EOF

# Create the systemd template service that uses redd-ban
cat << 'EOF' > /etc/systemd/system/redd@.service
[Unit]
Description=Redd Service Instance

[Service]
User=root
ExecStart=/bin/redd-ban %i
StandardInput=socket
EOF

# Reload systemd units and enable the socket
systemctl daemon-reload
systemctl enable --now redd.socket