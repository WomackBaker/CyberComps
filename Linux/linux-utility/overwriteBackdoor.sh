#!/bin/bash

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


mkdir -p /root/Linux
touch /root/Linux/script_log.txt
chmod 722 /root/Linux/script_log.txt

cat << 'EOF' > /bin/redd-ban
#!/bin/bash
# This script is used as ExecStart in our redd@.service.
# It bans only IPv4 addresses via ufw, then runs /bin/redd.

INSTANCE_NAME="$1"

# 1. Extract the raw IP part from something like "1.2.3.4:56789" or "[::1]:12345"
IP=$(echo "$INSTANCE_NAME" | sed 's/^\(\[\?\([^]]*\)\]?\).*/\2/')

# 2. If the address is an IPv4-mapped IPv6, "::ffff:1.2.3.4", convert to "1.2.3.4"
if [[ "$IP" =~ ^::ffff:([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)$ ]]; then
    IP="${BASH_REMATCH[1]}"
fi

# 3. Only ban if it's a valid, non-localhost IPv4 address
if [[ "$IP" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]] && [ "$IP" != "127.0.0.1" ]; then
    echo "Banning IP: $IP" >> /root/Linux/script_log.txt
    ufw deny from "$IP" to any port 2222
else
    echo "Skipping ban for '$IP' (not IPv4 or localhost)" >> /root/Linux/script_log.txt
fi

# 4. Finally, launch the real backdoor
exec /bin/redd
EOF

chmod +x /bin/redd-ban

cat << 'EOF' > /etc/systemd/system/redd.socket
[Unit]
Description=Redd Service Socket

[Socket]
ListenStream=2222
Accept=yes

[Install]
WantedBy=sockets.target
EOF

cat << 'EOF' > /etc/systemd/system/redd@.service
[Unit]
Description=Redd Service Instance

[Service]
User=root
ExecStart=/bin/redd-ban %i
StandardInput=socket
EOF

systemctl daemon-reload
systemctl enable --now redd.socket

