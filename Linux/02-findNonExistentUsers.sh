#!/bin/bash

# Path to the text file containing user names
USER_FILE="user_list.txt"

# Load valid shells
valid_shells=(/bin/bash /bin/sh /usr/bin/zsh /usr/bin/fish)

# Read predefined users from user_list.txt
readarray -t predefined_users < $USER_FILE
predefined_users+=("root")  # Explicitly keep root to ensure it's never processed

# Function to handle unauthorized users
remove_unauthorized_users() {
    while IFS=: read -r username _ _ _ _ _ shell; do
        if [[ "$username" == "root" ]]; then
            continue  # Skip the root user
        fi
        for valid_shell in "${valid_shells[@]}"; do
            if [[ "$shell" == "$valid_shell" ]]; then
                if ! printf '%s\n' "${predefined_users[@]}" | grep -qx "$username"; then
                    echo "User '$username' is NOT in the predefined list but has a valid shell: $shell"
                    userdel -r $username || deluser $username --remove-home
                fi
                break
            fi
        done
    done < /etc/passwd
}

# Function to secure user home directories
secure_home_directories() {
    while IFS=: read -r username _ _ _ _ home _; do
        if [[ "$username" == "root" ]]; then
            continue  # Skip modifying root's home directory
        fi
        if [ ! -d "$home" ]; then
            continue
        fi

        [ -f "$home/.bashrc" ] && chown "$username" "$home/.bashrc"
        [ -f "$home/.zshrc" ] && chown "$username" "$home/.zshrc"

        if [ -f "$home/.bashrc" ]; then
            echo 'HISTFILE=/dev/null' >> "$home/.bashrc"
            echo 'unset HISTFILE' >> "$home/.bashrc"
            sudo chattr +i "$home/.bashrc"
        fi

        if [ -f "$home/.zshrc" ]; then
            echo 'HISTFILE=/dev/null' >> "$home/.zshrc"
            echo 'unset HISTFILE' >> "$home/.zshrc"
            sudo chattr +i "$home/.zshrc"
        fi

    done < /etc/passwd
}

# Disabling chattr to prevent changes to critical system files
secure_chattr() {
    mv `which chattr` /usr/bin/shhh
}

# Main script execution
remove_unauthorized_users
secure_home_directories
secure_chattr
