#!/bin/bash

USER_FILE="$HOME/Linux/user_list.txt"
EXCLUDE_FILE="$HOME/Linux/exclude.txt"

while true; do

    ########################################################
    # 1. Read admin & normal users from user_list.txt
    ########################################################

    if [[ ! -f "$USER_FILE" ]]; then
        echo "Error: $USER_FILE does not exist. Exiting..."
        exit 1
    fi

    # We expect exactly two lines in user_list.txt:
    #   1) Admin users
    #   2) Normal users
    mapfile -t lines < "$USER_FILE"

    if [[ ${#lines[@]} -lt 2 ]]; then
        echo "Error: $USER_FILE must have at least two lines (admins on line 1, normal users on line 2)."
        exit 1
    fi

    # Parse first line as admin users, second line as normal users
    IFS=' ' read -r -a administratorGroup <<< "${lines[0]}"
    IFS=' ' read -r -a normalUsers <<< "${lines[1]}"

    # Always keep root in the admin group (if not already listed)
    if [[ ! " ${administratorGroup[*]} " =$HOME " root " ]]; then
        administratorGroup+=("root")
    fi

    # Combine admin + normal to get our "predefined" set
    predefined_users=( "${administratorGroup[@]}" "${normalUsers[@]}" )

    ########################################################
    # 2. Read exclude file (users never to be removed)
    ########################################################
    declare -a excludeUsers=()

    if [[ -f "$EXCLUDE_FILE" ]]; then
        # Read each line, skip if line is empty or begins with #
        while IFS= read -r line; do
            [[ -z "$line" || "$line" =$HOME ^# ]] && continue
            excludeUsers+=( "$line" )
        done < "$EXCLUDE_FILE"
    else
        echo "Warning: $EXCLUDE_FILE not found. No extra users excluded."
    fi

    ########################################################
    # 3. Remove all users with a valid shell if not in our list
    ########################################################
    valid_shells=(/bin/bash /bin/sh /usr/bin/zsh /usr/bin/fish)

    while IFS=: read -r username _ _ _ _ _ shell; do
        # Skip if user is in exclude file
        if printf '%s\n' "${excludeUsers[@]}" | grep -qx "$username"; then
            # This user is explicitly excluded from removal
            continue
        fi

        # Check if shell is valid
        for valid_shell in "${valid_shells[@]}"; do
            if [[ "$shell" == "$valid_shell" ]]; then
                # If user with a valid shell is not in predefined_users, remove them
                if ! printf '%s\n' "${predefined_users[@]}" | grep -qx "$username"; then
                    echo "User '$username' is NOT in our user list but has a valid shell ($shell). Removing..."
                    # Kill the user's processes
                    pkill --signal SIGKILL -u "$username" 2>/dev/null
                    # Try userdel, fallback to deluser
                    if ! userdel -r "$username" 2>/dev/null; then
                        deluser --remove-home "$username" 2>/dev/null
                    fi
                fi
                break
            fi
        done
    done < /etc/passwd

    ########################################################
    # 4. Ensure admins exist and are in sudo
    ########################################################
    for admin in "${administratorGroup[@]}"; do
        # Create admin if doesn't exist
        if ! id "$admin" &>/dev/null; then
            useradd -m "$admin"
            echo "User $admin created."
        fi
        # Ensure each admin is in the sudo group
        if ! id "$admin" | grep -qw sudo; then
            usermod -aG sudo "$admin"
            echo "$admin added to sudo group."
        fi
    done

    ########################################################
    # 5. Ensure normal users exist and are NOT in sudo
    ########################################################
    for user in "${normalUsers[@]}"; do
        # Create normal user if doesn't exist
        if ! id "$user" &>/dev/null; then
            useradd -m "$user"
            echo "User $user created."
        fi
        # Remove from sudo group if currently a member
        if id "$user" | grep -qw 'sudo'; then
            gpasswd -d "$user" sudo
            echo "Removed $user from the sudo group."
        fi
    done

    ########################################################
    # 6. Sleep & Repeat
    ########################################################
    sleep 30

done