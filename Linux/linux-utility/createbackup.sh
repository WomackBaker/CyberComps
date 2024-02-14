#!/bin/bash

# Back ups important directories into /root
# Make sure zip is installed

if [ $(whoami) != "root" ]; then
    echo "Script must be run as root"
    exit 1
fi

# Define the directories to backup
backup_directories="/etc /home /bin /var/www /usr/bin"

# Zip the specified directories into the backup directory
zip -r "/root/backup.zip" $backup_directories

# Rename the backup file to the specified name
mv "/root/backup.zip" "/root/8dbeddf9445b769c9f0e65b3a7867357"
