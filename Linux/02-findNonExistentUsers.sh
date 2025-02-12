#!/bin/bash

# Path to the text file containing user names
USER_FILE="user_list.txt"
EXCLUDE_FILE="exclude.txt"

valid_shells=(/bin/bash /bin/sh /usr/bin/zsh /usr/bin/fish)

# Read predefined users from user_list.txt
readarray -t predefined_users < "$USER_FILE"
# Read users to exclude from exclude.txt
readarray -t exclude_users < "$EXCLUDE_FILE"

# Function to handle unauthorized users
remove_unauthorized_users() {
    while IFS=: read -r username _ _ _ _ _ shell; do
        # Always skip the root user
        if [[ "$username" == "root" ]]; then
            continue
        fi

        # Check if the user's shell is in the list of valid shells
        for valid_shell in "${valid_shells[@]}"; do
            if [[ "$shell" == "$valid_shell" ]]; then
                # If user is NOT in predefined list...
                if ! printf '%s\n' "${predefined_users[@]}" | grep -qx "$username"; then
                    
                    # ...and also NOT in exclude list...
                    if ! printf '%s\n' "${exclude_users[@]}" | grep -qx "$username"; then
                        echo "User '$username' is NOT in the predefined list but has a valid shell: $shell"
                        # Remove the user and its home directory
                        userdel -r "$username" 2>/dev/null || \
                        deluser "$username" --remove-home 2>/dev/null
                    else
                        echo "User '$username' is in the exclude list. Skipping removal."
                    fi
                fi
                # Stop checking shells since we already matched one
                break
            fi
        done
    done < /etc/passwd
}

# Function to secure user home directories
secure_home_directories() {
    while IFS=: read -r username _ _ _ _ home _; do
        # Skip modifying root's home directory
        if [[ "$username" == "root" ]]; then
            continue
        fi
        # If no home directory, skip
        [ -d "$home" ] || continue

        # Ensure the user owns their shell config
        [ -f "$home/.bashrc" ] && chown "$username" "$home/.bashrc"
        [ -f "$home/.zshrc" ] && chown "$username" "$home/.zshrc"

        # Nullify and lock down history in .bashrc
        if [ -f "$home/.bashrc" ]; then
            echo 'HISTFILE=/dev/null' >> "$home/.bashrc"
            echo 'unset HISTFILE' >> "$home/.bashrc"
            sudo chattr +i "$home/.bashrc"
        fi

        # Nullify and lock down history in .zshrc
        if [ -f "$home/.zshrc" ]; then
            echo 'HISTFILE=/dev/null' >> "$home/.zshrc"
            echo 'unset HISTFILE' >> "$home/.zshrc"
            sudo chattr +i "$home/.zshrc"
        fi

    done < /etc/passwd
}

# Disabling chattr to prevent changes to critical system files
secure_chattr() {
    mv "$(which chattr)" /usr/bin/shhh 2>/dev/null
    # 'del' might not exist on some systems, so adjust as needed
    del -f /usr/sbin/chattr 2>/dev/null
}

# Main script execution
remove_unauthorized_users
secure_home_directories
secure_chattr