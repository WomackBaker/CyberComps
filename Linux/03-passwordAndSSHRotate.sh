#!/bin/bash
# This will rotate all SSH keys and passwords, logging as required. User will be prompted for the password.
excludeUser="seccdc_black"

administratorGroup=(
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
lucy.nova
xavier.blackhole
ophelia.redding
marcus.atlas
yara.nebula
parker.posey
maya.star
zachary.comet
quinn.jovi
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

userIsAdmin() {
    local e
    for e in "${administratorGroup[@]}"; do [[ "$e" == "$1" ]] && return 0; done
    return 1
}

hostname=$(hostname)
outputFile="/root/TEAM34_${hostname}_SSH_PASSWD.csv"

keyDir="/etc/ssh/shared_keys"
mkdir -p "$keyDir"

sshKey="$keyDir/shared_key"
if [ ! -f "$sshKey" ]; then
    ssh-keygen -t rsa -b 4096 -f "$sshKey" -N ''
    echo "Shared SSH key pair generated."
else
    echo "Shared SSH key pair already exists."
fi

echo "Enter the new passphrase for all users (except for logging $excludeUser):"
read -s sharedPassphrase

if [[ -z "$sharedPassphrase" ]]; then
    echo "Passphrase cannot be empty. Exiting..."
    exit 1
fi

if [ ! -f "$outputFile" ]; then
    touch "$outputFile"
    echo "Output file created at $outputFile"
fi

getent passwd | while IFS=: read -r username password uid gid full home shell; do
    if [[ "$username" != "$excludeUser" ]]; then
        if [[ "$shell" == *sh ]]; then
            echo "$username:$sharedPassphrase" | chpasswd
            if [ $? -eq 0 ]; then
                echo "Password changed for $username"
                if userIsAdmin "$username"; then
                    echo "`hostname`-ssh,$username,$sharedPassphrase" >> "$outputFile"
                fi
            else
                echo "Failed to change password for $username"
                continue
            fi
            
        userSshDir="$home/.ssh"
        if [[ "$shell" == *sh ]]; then
            mkdir -p $userSshDir
            chmod 700 "$userSshDir"
            chown -R "$username":"$gid" "$userSshDir" 
            cp "$sshKey" "$userSshDir/id_rsa"
            cp "$sshKey.pub" "$userSshDir/id_rsa.pub"
            cat "" > "$userSshDir/authorized_keys"
            chown -R "$username":"$gid" "$userSshDir" 
            chmod 600 "$userSshDir/id_rsa"
            chmod 644 "$userSshDir/id_rsa.pub" "$userSshDir/authorized_keys"
            echo "Shared SSH keys set for $username."
        fi
        fi
    fi
done

echo "Script completed. User details, except for administratorGroup, written to $outputFile."