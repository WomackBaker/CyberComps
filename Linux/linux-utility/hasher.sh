#!/bin/bash

# Hash the files
shadow_hash=$(sha256sum /etc/shadow | awk '{ print $1 }')
passwd_hash=$(sha256sum /etc/passwd | awk '{ print $1 }')

# Read the hashes from the text file
read -r stored_shadow_hash stored_passwd_hash < hashes.txt

# Compare the hashes
if [ "$shadow_hash" = "$stored_shadow_hash" ] && [ "$passwd_hash" = "$stored_passwd_hash" ]; then
    echo "The hashes match."
else
    echo "**ALERT** - $(date) " >> /var/log/hasher.log
fi