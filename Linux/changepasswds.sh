#!/bin/bash

# Check if the script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root"
  exit 1
fi

# Get the list of all users
users=$(awk -F: '$3 >= 1000 {print $1}' /etc/passwd)

# Prompt for the new password
read -s -p "Enter the new password for all users: " new_password
echo

# Change the password for each user
for user in $users; do
  echo "$user:$new_password" | chpasswd
  if [ $? -eq 0 ]; then
    echo "Password changed successfully for user: $user"
  else
    echo "Failed to change password for user: $user"
  fi
done

echo "Password change process completed."
