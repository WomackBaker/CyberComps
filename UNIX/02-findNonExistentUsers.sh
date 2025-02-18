#!/usr/bin/env bash

# Path to the text file containing user names
USER_FILE="$HOME/Linux/user_list.txt"
EXCLUDE_FILE="$HOME/Linux/exclude.txt"

# Update valid shell paths for FreeBSD installations
valid_shells=(/usr/local/bin/bash /bin/sh /usr/local/bin/zsh /usr/local/bin/fish)

# Read predefined users from user_list.txt ignoring section headers and blank lines
readarray -t predefined_users < <(grep -v ':$' "$USER_FILE" | sed '/^\s*$/d')
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
                        # Remove the user and its home directory using FreeBSD's pw command
                        pw userdel "$username" -r 2>/dev/null
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

        # Ensure the user owns their shell config files
        [ -f "$home/.bashrc" ] && chown "$username" "$home/.bashrc"
        [ -f "$home/.zshrc" ] && chown "$username" "$home/.zshrc"

        # Nullify and lock down history in .bashrc
        if [ -f "$home/.bashrc" ]; then
            echo 'HISTFILE=/dev/null' >> "$home/.bashrc"
            echo 'unset HISTFILE' >> "$home/.bashrc"
            chflags schg "$home/.bashrc"
        fi

        # Nullify and lock down history in .zshrc
        if [ -f "$home/.zshrc" ]; then
            echo 'HISTFILE=/dev/null' >> "$home/.zshrc"
            echo 'unset HISTFILE' >> "$home/.zshrc"
            chflags schg "$home/.zshrc"
        fi

    done < /etc/passwd
}

# Function to secure chattr (Not applicable on FreeBSD)
secure_chattr() {
    echo "secure_chattr: 'chattr' is not applicable on FreeBSD. Skipping."
}

echo "FINISHED"

# Main script execution
remove_unauthorized_users
secure_home_directories
secure_chattr
