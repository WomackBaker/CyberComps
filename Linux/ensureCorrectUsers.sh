#!/bin/bash

# The usage of this script, is a repeating loop that ensures the required users exist with admin access.
while true; do
    ###################################################### SCORECHECK USER #################################################
    DONOTTOUCH=(

    )
    ###################################################### SCORECHECK USER #################################################


    ###################################################### Delete users ###################################################
    valid_shells=(/bin/bash /bin/sh /usr/bin/zsh /usr/bin/fish)

    predefined_users=(
    $1
    $2
    $3
    root
    ubuntu
    )

    while IFS=: read -r username _ _ _ _ _ shell; do
        for valid_shell in "${valid_shells[@]}"; do
            if [[ "$shell" == "$valid_shell" ]]; then
                if ! printf '%s\n' "${predefined_users[@]}" | grep -qx "$username"; then
                    echo "User '$username' is NOT in the predefined list but has a valid shell: $shell"
                    pkill --signal SIGKILL -u $username
                    userdel -r $username || deluser $username --remove-home
                fi
                break
            fi
        done
    done < /etc/passwd

    ###################################################### ADMINS #################################################
    administratorGroup=( 
    root
    ubuntu
    )

    for admin in "${administratorGroup[@]}"; do
        if ! id "$admin" &>/dev/null; then
            useradd -m "$admin"
            echo "User $admin created."
        fi

        if ! id "$admin" | grep -qw sudo; then
            usermod -aG sudo "$admin"
            echo "$admin added to sudo group."
        fi
    done


    ###################################################### NORMAL USERS #################################################
    normalUsers=(
    )

    ############################## ADDING AND REMOVING ADMINISTRATORS

    echo "######Ensuring normal users exist and are not part of the sudo group#####"
    for user in "${normalUsers[@]}"; do
        if ! id "$user" &>/dev/null; then
            useradd -m "$user"
            echo "User $user created."
        fi
        if id "$user" | grep -qw 'sudo'; then
            gpasswd -d "$user" sudo
            echo "Removed $user from the sudo group."
        fi
    done

    sleep 30
done
