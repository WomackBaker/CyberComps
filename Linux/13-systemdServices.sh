#!/bin/bash

# Update repositories and install Python 3 quietly (Debian/Ubuntu)
apt-get update -y >/dev/null 2>&1
apt-get install -y python3 >/dev/null 2>&1

# Attempt installation on CentOS (won't harm Debian/Ubuntu if yum isn't present)
yum install -y python3 >/dev/null 2>&1

# Capture all arguments passed to the script
args="$@"

############################
# pkillBash.service
############################
cat <<EOF >/etc/systemd/system/pkillBash.service
[Unit]
Description=Run pkillBash script
After=network.target

[Service]
ExecStart=/bin/bash $HOME/Linux/linux-utility/pkillBash.sh
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

############################
# ensureCorrectUsers.service
############################
cat <<EOF >/etc/systemd/system/ensureCorrectUsers.service
[Unit]
Description=Run ensureCorrectUsers script
After=network.target

[Service]
ExecStart=/bin/bash $HOME/Linux/linux-utility/ensureCorrectUsers.sh
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

############################
# hasher.service
############################
cat <<EOF >/etc/systemd/system/hasher.service
[Unit]
Description=Run hasher script
After=network.target

[Service]
ExecStart=/bin/bash $HOME/Linux/linux-utility/hasher.sh
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

############################
# serviceCheck.service
############################
# NOTE: The script below uses relative paths for services.txt and script_log.txt.
#       You can either place those files in /root/Linux (with the script),
#       or adjust the WorkingDirectory and ExecStart accordingly.
cat <<EOF >/etc/systemd/system/serviceCheck.service
[Unit]
Description=Kill unlisted services
After=network.target

[Service]
ExecStart=/bin/bash $HOME/Linux/linux-utility/serviceCheck.sh
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF


############################
# netstatCheck.service
############################
# NOTE: The script below uses relative paths for services.txt and script_log.txt.
#       You can either place those files in /root/Linux (with the script),
#       or adjust the WorkingDirectory and ExecStart accordingly.
cat <<EOF >/etc/systemd/system/netstatCheck.service
[Unit]
Description=Kill unlisted connections
After=network.target

[Service]
ExecStart=/bin/bash $HOME/Linux/linux-utility/netstatCheck.sh
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd so it recognizes the new/updated service definitions
systemctl daemon-reload

# Enable and start pkillBash service
systemctl enable pkillBash.service
systemctl start pkillBash.service

# Enable and start ensureCorrectUsers service
systemctl enable ensureCorrectUsers.service
systemctl start ensureCorrectUsers.service

# Enable and start hasher service
systemctl enable hasher.service
systemctl start hasher.service

# Enable and start killUnlistedServices service
systemctl enable serviceCheck.service
systemctl start serviceCheck.service

# Enable and start killUnlistedServices service
systemctl enable netstatCheck.service
systemctl start netstatCheck.service

# Optionally display the status of the services
systemctl status pkillBash.service
systemctl status ensureCorrectUsers.service
systemctl status hasher.service
systemctl status serviceCheck.service
systemctl status netstatCheck.service
