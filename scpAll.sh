#!/bin/bash

username=$1
password=$2

# List of IPs to copy to
ips=("192.168.0.1" "192.168.0.2")  # Add more IPs as needed

# Loop over each IP and copy the folder
for ip in "${ips[@]}"; do
  echo "Copying to $username@$ip..."
  sshpass -p "$password" scp -r ./Linux "$username@$ip:/home/$username/Linux"
done
