#!/bin/bash

# Hash the files
shadow_hash=$(sha256sum /etc/shadow | awk '{ print $1 }')
passwd_hash=$(sha256sum /etc/passwd | awk '{ print $1 }')

echo "shadow_hash: $shadow_hash" >> hash.txt
echo "passwd_hash: $passwd_hash" >> hash.txt