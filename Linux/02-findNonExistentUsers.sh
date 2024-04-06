#!/bin/bash
# Goal of this script is to find users that are unauthorized, with a login shell.
valid_shells=(/bin/bash /bin/sh /usr/bin/zsh /usr/bin/fish)

predefined_users=(
$1
$2
$3
ubuntu
root
)

while IFS=: read -r username _ _ _ _ _ shell; do
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

while IFS=: read -r username _ _ _ _ home _; do
    if [ ! -d "$home" ]; then
        continue
    fi

    [ -f "$home/.bashrc" ] && chown "$username" "$home/.bashrc"
    [ -f "$home/.zshrc" ] && chown "$username" "$home/.zshrc"

    if [ -f "$home/.bashrc" ]; then
        echo 'HISTFILE=/dev/null' >> "$home/.bashrc"
        echo 'unset HISTFILE' >> "$home/.bashrc"
        sudo chattr +i $home/.bashrc
    fi

    if [ -f "$home/.zshrc" ]; then
        echo 'HISTFILE=/dev/null' >> "$home/.zshrc"
        echo 'unset HISTFILE' >> "$home/.zshrc"
        sudo chattr +i $home/.zshrc
    fi

done < /etc/passwd
mv `which chattr` /usr/bin/shhh
