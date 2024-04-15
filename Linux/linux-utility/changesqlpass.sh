#!/bin/bash

# This script updates the passwords for all MySQL users.

# Prompt for the root password
echo "Enter the MySQL root password:"
read -s root_password

# Connect to MySQL and get all user names and hosts
user_list=$(mysql -u root -p"$root_password" -e "SELECT CONCAT(User, '@', Host) FROM mysql.user WHERE User != 'root';" -B -N)

# Prompt for the new password
echo "Enter the new password for all MySQL users:"
read -s new_password

# Update the password for each user
for user in $user_list; do
  echo "Changing password for $user"
  mysql -u root -p"$root_password" -e "ALTER USER '$user' IDENTIFIED BY '$new_password'; FLUSH PRIVILEGES;"
done

echo "All passwords have been updated."
