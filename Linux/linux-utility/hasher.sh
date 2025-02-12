#!/bin/bash

# 1. Generate new/current hashes for passwd and shadow
current_passwd_hash="$(sha256sum /etc/passwd | awk '{print $1}')"
current_shadow_hash="$(sha256sum /etc/shadow | awk '{print $1}')"

# 2. Read stored hashes from hashes.txt
#    Format of hashes.txt is assumed:
#      passwd: <hash>
#      shadow: <hash>
stored_passwd_hash="$(awk -F': ' '/^passwd_hash:/{print $2}' /root/Linux/linux-utility/hash.txt)"
stored_shadow_hash="$(awk -F': ' '/^shadow_hash:/{print $2}' /root/Linux/linux-utility/hash.txt)"

# 3. Compare them
if [[ "$current_passwd_hash" == "$stored_passwd_hash" && \
      "$current_shadow_hash" == "$stored_shadow_hash" ]]; then
    echo "The /etc/passwd and /etc/shadow hashes match the stored values."
else
    echo "The /etc/passwd and /etc/shadow hashes DO NOT match the stored values."
    echo "**ALERT PASSWORD CHANGED** - $(date)" >> /root/Linux/script_log.txt
fi