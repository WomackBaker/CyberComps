#!/bin/bash
# Goal of this script is to find users that are unauthorized, with a login shell.
valid_shells=(/bin/bash /bin/sh /usr/bin/zsh /usr/bin/fish)

predefined_users=(
$1
$2
$3
elara.boss
sarah.lee
lisa.brown
michael.davis
emily.chen
tom.harris
bob.johnson
david.kim
rachel.patel
dave.grohl
kate.skye
leo.zenith
jack.rover
root
lucy.nova
xavier.blackhole
ophelia.redding
marcus.atlas
yara.nebula
parker.posey
maya.star
zachary.comet
quinn.jovi
seccdc_black
nina.eclipse
alice.bowie
ruby.rose
owen.mars
bob.dylan
samantha.stephens
parker.jupiter
carol.rivers
taurus.tucker
rachel.venus
emily.waters
una.veda
ruby.starlight
frank.zappa
ava.stardust
samantha.aurora
grace.slick
benny.spacey
sophia.constellation
harry.potter
celine.cosmos
tessa.nova
ivy.lee
dave.marsden
thomas.spacestation
kate.bush
emma.nova
una.moonbase
luna.lovegood
frank.astro
victor.meteor
mars.patel
grace.luna
wendy.starship
neptune.williams
henry.orbit
ivy.starling
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
