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
INSTANCE_NAME="$1"

IP="$(echo "$INSTANCE_NAME" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' | tail -1)"

if [[ "$IP" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]] && [ "$IP" != "127.0.0.1" ]; then
    ufw deny from "$IP" to any port 2222
fi

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

