#!/bin/bash

###############################################################################
# Ensure script is run with root privileges or via sudo
###############################################################################
if [[ "$EUID" -ne 0 ]]; then
  echo "ERROR: This script must be run as root or via sudo."
  exit 1
fi

###############################################################################
# Determine the "real" home directory of the user invoking the script, 
# even if running with sudo.
###############################################################################
if [[ -n "$SUDO_USER" ]]; then
  # If running via sudo, SUDO_USER is set to the login name of the user who invoked sudo.
  REAL_USER="$SUDO_USER"
else
  # If not running via sudo, use the current effective user. This may be 'root'.
  REAL_USER="$USER"
fi

# Evaluate the ~ expansion for that user. This handles non-/home/ paths as well.
REAL_HOME="$(eval echo "~${REAL_USER}")"

# Paths to text files (use the real user's home, not root's home, if run via sudo).
USER_FILE="$REAL_HOME/Linux/user_list.txt"
EXCLUDE_FILE="$REAL_HOME/Linux/exclude.txt"

###############################################################################
# Set the valid shells
###############################################################################
valid_shells=(/bin/bash /bin/sh /usr/bin/zsh /usr/bin/fish)

###############################################################################
# Check for existence of required files
###############################################################################
if [[ ! -f "$USER_FILE" ]]; then
  echo "ERROR: Cannot find $USER_FILE."
  exit 1
fi

if [[ ! -f "$EXCLUDE_FILE" ]]; then
  echo "ERROR: Cannot find $EXCLUDE_FILE."
  exit 1
fi

###############################################################################
# Read the user lists
###############################################################################
# Read predefined users from user_list.txt ignoring section headers and blank lines
readarray -t predefined_users < <(grep -v ':$' "$USER_FILE" | sed '/^\s*$/d')

# Read users to exclude from exclude.txt
readarray -t exclude_users < "$EXCLUDE_FILE"

###############################################################################
# Function: remove_unauthorized_users
###############################################################################
remove_unauthorized_users() {
    while IFS=: read -r username _ _ _ _ _ shell; do
        # Skip the root user
        if [[ "$username" == "root" ]]; then
            continue
        fi

        # Check if the user's shell is in the list of valid shells
        for valid_shell in "${valid_shells[@]}"; do
            if [[ "$shell" == "$valid_shell" ]]; then
                # If user is NOT in the predefined list
                if ! printf '%s\n' "${predefined_users[@]}" | grep -qx "$username"; then
                    # ...and also NOT in the exclude list
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

###############################################################################
# Function: secure_home_directories
###############################################################################
secure_home_directories() {
    while IFS=: read -r username _ _ _ _ home _; do
        # Skip modifying root's home directory
        if [[ "$username" == "root" ]]; then
            continue
        fi

        # If no home directory, skip
        [[ -d "$home" ]] || continue

        # Ensure the user owns their shell config
        [[ -f "$home/.bashrc" ]] && chown "$username" "$home/.bashrc"
        [[ -f "$home/.zshrc" ]] && chown "$username" "$home/.zshrc"

        # Nullify and lock down history in .bashrc
        if [[ -f "$home/.bashrc" ]]; then
            echo 'HISTFILE=/dev/null' >> "$home/.bashrc"
            echo 'unset HISTFILE'     >> "$home/.bashrc"
            chattr +i "$home/.bashrc"
        fi

        # Nullify and lock down history in .zshrc
        if [[ -f "$home/.zshrc" ]]; then
            echo 'HISTFILE=/dev/null' >> "$home/.zshrc"
            echo 'unset HISTFILE'     >> "$home/.zshrc"
            chattr +i "$home/.zshrc"
        fi

    done < /etc/passwd
}

###############################################################################
# Function: secure_chattr
# Disabling chattr to prevent changes to locked-down files
###############################################################################
secure_chattr() {
    # Attempt to rename chattr binary if it exists in the expected place
    if command -v chattr &>/dev/null; then
        mv "$(which chattr)" /usr/bin/shhh 2>/dev/null
    fi

    # 'del' might not exist on some systems; this is just an example line.
    # Remove or modify as needed.
    del -f /usr/sbin/chattr 2>/dev/null
}

###############################################################################
# Main script execution
###############################################################################
remove_unauthorized_users
secure_home_directories
secure_chattr

echo "FINISHED"
