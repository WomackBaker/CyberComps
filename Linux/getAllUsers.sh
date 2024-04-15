#!/bin/bash

# Extracts the username from each line in /etc/passwd
awk -F':' '{ print $1 }' /etc/passwd > user_list.txt

echo "User list has been saved to user_list.txt"
