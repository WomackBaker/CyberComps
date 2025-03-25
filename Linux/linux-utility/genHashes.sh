#!/bin/bash

# Location of the output file:
OUTFILE="$HOME/Linux/linux-utility/hashes.txt"

# Ensure script is being run with sufficient privileges to read /etc/shadow
if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root (sudo) to read /etc/shadow."
  exit 1
fi

# Create or overwrite the output file
> "$OUTFILE"

# 1. Hash the entire /etc/shadow and /etc/passwd files
shadow_hash=$(sha256sum /etc/shadow | awk '{ print $1 }')
passwd_hash=$(sha256sum /etc/passwd | awk '{ print $1 }')

echo "shadow_hash: $shadow_hash" >> "$OUTFILE"
echo "passwd_hash: $passwd_hash" >> "$OUTFILE"
echo "" >> "$OUTFILE"

# 2. For each user in /etc/passwd, find and hash:
#    - That user's line in /etc/passwd
#    - That user's line in /etc/shadow (if it exists)
while IFS=: read -r username _ uid gid gecos home shell
do
  # Grab the exact line from /etc/passwd
  passwd_line=$(grep "^$username:" /etc/passwd)
  # Grab the exact line from /etc/shadow
  shadow_line=$(grep "^$username:" /etc/shadow 2>/dev/null)

  # If there's no corresponding line in /etc/shadow (e.g., system user),
  # we'll note that as well:
  if [[ -z "$shadow_line" ]]; then
    shadow_line="No shadow entry for user: $username"
  fi

  # Hash the lines
  passwd_line_hash=$(echo "$passwd_line" | sha256sum | awk '{print $1}')
  shadow_line_hash=$(echo "$shadow_line" | sha256sum | awk '{print $1}')

  # Write them to the file
  echo "User: $username" >> "$OUTFILE"
  echo "  passwd_line_hash: $passwd_line_hash" >> "$OUTFILE"
  echo "  shadow_line_hash: $shadow_line_hash" >> "$OUTFILE"
  echo "" >> "$OUTFILE"

done < /etc/passwd

echo "Hashes have been written to: $OUTFILE"
