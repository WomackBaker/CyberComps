#!/bin/bash
# Will automatically enumerate and remove dangerous SUID binaries.
echo "==================================="
echo " SUIDER - SUID Exploit Finder Tool "
echo "==================================="

echo "[+] Looking for standard exploitable SUID binaries...."
r=$(find / -perm -u=s -type f 2>/dev/null | rev | cut -d'/' -f 1 | rev)


output=($r)
dict=(aria2c arp ash base32 base64 basenc bash busybox capsh cat chmod chown chroot column comm cp csh csplit curl cut dash date dd dialog diff dmsetup docker emacs env eqn expand expect find flock fmt fold gdb gimp grep gtester hd head hexdump highlight iconv install ionice ip jjs join jq jrunscript ksh ks ld.so less logsave look lwp-download lwp-request make more mv nano nice nl node nohup od openssl paste perl pg php pico pr python readelf restic rev rlwrap rpm rpmquery rsync run-parts rview rvim sed setarch shuf soelim sort ss ssh-keyscan start-stop-daemon stdbuf strace strings sysctl systemctl tac tail taskset tbl tclsh tee tftp time timeout troff ul unexpand uniq unshare update-alternatives uudecode uuencode view vim watch wget xargs xmodmap xxd xz zsh zsoelim)

result=()

for a in "${output[@]}"; do
    for b in "${dict[@]}"; do
        if [[ $a == "$b" ]]; then
            result+=( "$a" )
            break
        fi
    done
done

if [[ -z ${result[@]} ]]
then 
    echo "[-] Nothing Found!"

else

    echo '---------------------------------'
    echo " REMOVING SUID BIT FROM BINARIES"
    echo '---------------------------------'

    for i in "${result[@]}"
    do
        full_path=$(which "$i" 2>/dev/null)
        if [[ -n $full_path ]]; then
            echo "[+] Removing SUID bit from: $full_path"
            sudo chmod -s "$full_path"
        else
            echo "[-] Binary not found in PATH: $i"
        fi
    done
fi
