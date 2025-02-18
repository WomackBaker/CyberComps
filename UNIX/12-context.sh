#!/usr/bin/env bash

echo "############# Checking CronTabs in /etc/crontab"
cat /etc/crontab

# Distribution flags
IS_RHEL=false
IS_DEBIAN=false
IS_ALPINE=false
IS_SLACK=false
IS_BSD=false

# Color variables (if COLOR is set)
ORAG=''
GREEN=''
YELLOW=''
BLUE=''
RED=''
NC=''

if [ -z "$DEBUG" ]; then
    DPRINT() { 
        "$@" 2>/dev/null 
    }
else
    DPRINT() { 
        "$@" 
    }
fi

RHEL(){
  IS_RHEL=true
}

DEBIAN(){
  IS_DEBIAN=true
}

UBUNTU(){
  DEBIAN
}

ALPINE(){
  IS_ALPINE=true
}

SLACK(){
  IS_SLACK=true
}

# Detect Linux distributions using package managers
if command -v yum >/dev/null ; then
    RHEL
elif command -v apt-get >/dev/null ; then
    if grep -qi Ubuntu /etc/os-release 2>/dev/null; then
        UBUNTU
    else
        DEBIAN
    fi
elif command -v apk >/dev/null ; then
    ALPINE
elif command -v slapt-get >/dev/null || grep -qi slackware /etc/os-release 2>/dev/null ; then
    SLACK
fi

# Detect BSD systems
UNAME=$(uname -s)
if [[ "$UNAME" == "FreeBSD" || "$UNAME" == "OpenBSD" || "$UNAME" == "NetBSD" ]]; then
    IS_BSD=true
fi

if [ -n "$COLOR" ]; then
    ORAG='\033[0;33m'
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;36m'
    NC='\033[0m'
fi

echo -e "${GREEN}
##################################
#                                #
#         INVENTORY TIME         #
#                                #
##################################
${NC}\n"

echo -e "\n${GREEN}############# HOST INFORMATION ############${NC}\n"

HOST=$( DPRINT hostname || DPRINT cat /etc/hostname )
# Use /etc/os-release if available; otherwise fallback to uname
if [ -f /etc/os-release ]; then
    OS=$( cat /etc/os-release | grep PRETTY_NAME | sed 's/PRETTY_NAME=//' | sed 's/"//g' )
else
    OS=$( uname -sr )
fi

# Get IP addresses. On FreeBSD, 'ip' may not exist so we use ifconfig.
if command -v ip >/dev/null ; then
    IP=$( DPRINT ip a | grep -oE '([[:digit:]]{1,3}\.){3}[[:digit:]]{1,3}/[[:digit:]]{1,2}' | grep -v '127.0.0.1' )
elif command -v ifconfig >/dev/null ; then 
    IP=$( DPRINT ifconfig | grep -oE 'inet ([[:digit:]]{1,3}\.){3}[[:digit:]]{1,3}' | grep -v '127.0.0.1' )
else
    IP="ip and ifconfig commands not found"
fi

# --- List current system users with valid shells ---
USERS=$( awk -F: '!/false|nologin|sync$/ && /\/.*sh$/ {print}' /etc/passwd )

# Gather sudoers info. (On some BSD systems sudoers may reside in /usr/local/etc.)
SUDOERS=$( { cat /etc/sudoers 2>/dev/null; cat /usr/local/etc/sudoers 2>/dev/null; cat /etc/sudoers.d/* 2>/dev/null; } | grep -vE '#|Defaults|^\s*$' | grep -vE '(Cmnd_Alias|\\)' )

# Find SUID binaries (works on Linux and BSD)
SUIDS=$(find /bin /sbin /usr -perm -u=s -type f -exec ls -la {} \; 2>/dev/null | grep -E '(s7z|aa-exec|ab|agetty|alpine|ansible-playbook|ansible-test|aoss|apt|apt-get|ar|aria2c|arj|arp|as|ascii85|ascii-xfr|ash|aspell|at|atobm|awk|aws|base32|base58|base64|basenc|basez|bash|batcat|bc|bconsole|bpftrace|bridge|bundle|bundler|busctl|busybox|byebug|bzip2|c89|c99|cabal|cancel|capsh|cat|cdist|certbot|check_by_ssh|check_cups|check_log|check_memory|check_raid|check_ssl_cert|check_statusfile|chmod|choom|chown|chroot|clamscan|cmp|cobc|column|comm|composer|cowsay|cowthink|cp|cpan|cpio|cpulimit|crash|crontab|csh|csplit|csvtool|cupsfilter|curl|cut|dash|date|dd|debugfs|dialog|diff|dig|distcc|dmesg|dmidecode|dmsetup|dnf|docker|dos2unix|dosbox|dotnet|dpkg|dstat|dvips|easy_install|eb|ed|efax|elvish|emacs|enscript|env|eqn|espeak|ex|exiftool|expand|expect|facter|file|find|finger|fish|flock|fmt|fold|fping|ftp|gawk|gcc|gcloud|gcore|gdb|gem|genie|genisoimage|ghc|ghci|gimp|ginsh|git|grc|grep|gtester|gzip|hd|head|hexdump|highlight|hping3|iconv|iftop|install|ionice|ip|irb|ispell|jjs|joe|join|journalctl|jq|jrunscript|jtag|julia|knife|ksh|ksshell|ksu|kubectl|latex|latexmk|ldconfig|ld.so|less|lftp|ln|loginctl|logsave|look|lp|ltrace|lua|lualatex|luatex|lwp-download|lwp-request|mail|make|man|mawk|minicom|more|mosquitto|msfconsole|msgattrib|msgcat|msgconv|msgfilter|msgmerge|msguniq|mtr|multitime|mv|mysql|nano|nasm|nawk|nc|ncftp|neofetch|nft|nice|nl|nm|nmap|node|nohup|npm|nroff|nsenter|octave|od|openssl|openvpn|openvt|opkg|pandoc|paste|pax|pdb|pdflatex|pdftex|perf|perl|perlbug|pexec|pg|php|pic|pico|pidstat|pip|pkexec|pkg|posh|pr|pry|psftp|psql|ptx|puppet|pwsh|python|rake|rc|readelf|red|redcarpet|redis|restic|rev|rlogin|rlwrap|rpm|rpmdb|rpmquery|rpmverify|rsync|rtorrent|ruby|run-mailcap|run-parts|runscript|rview|rvim|sash|scanmem|scp|screen|script|scrot|sed|service|setarch|setfacl|setlock|sftp|sg|shuf|slsh|smbclient|snap|socat|socket|soelim|softlimit|sort|split|sqlite3|sqlmap|ss|ssh|ssh-agent|ssh-keygen|ssh-keyscan|sshpass|start-stop-daemon|stdbuf|strace|strings|sysctl|systemctl|systemd-resolve|tac|tail|tar|task|taskset|tasksh|tbl|tclsh|tcpdump|tdbtool|tee|telnet|terraform|tex|tftp|tic|time|timedatectl|timeout|tmate|tmux|top|torify|torsocks|troff|tshark|ul|unexpand|uniq|unshare|unsquashfs|unzip|update-alternatives|uudecode|uuencode|vagrant|valgrind|vi|view|vigr|vim|vimdiff|vipw|virsh|volatility|w3m|wall|watch|wc|wget|whiptail|whois|wireshark|wish|xargs|xdg-user-dir|xdotool|xelatex|xetex|xmodmap|xmore|xpad|xxd|xz|yarn|yash|yelp|yum|zathura|zip|zsh|zsoelim|zypper)$')

# Find world-writable files
WORLDWRITEABLES=$( DPRINT find /usr /bin/ /sbin /var/www /lib -perm -o=w -type f -exec ls -la {} \; 2>/dev/null )

# Set SUDO group based on distro or BSD
if [ "$IS_RHEL" = true ] || [ "$IS_ALPINE" = true ] || [ "$IS_BSD" = true ]; then
    SUDOGROUP=$( grep wheel /etc/group | sed 's/x:.*:/ /' )
else
    SUDOGROUP=$( grep sudo /etc/group | sed 's/x:.*:/ /' )
fi

echo -e "${BLUE}[+] Hostname:${NC} $HOST"
echo -e "${BLUE}[+] OS:${NC} $OS"
echo -e "${BLUE}[+] IP Addresses and interfaces:${NC}"
echo -e "$IP\n"

echo -e "${BLUE}[+] Users:${NC}"
echo -e "${YELLOW}$USERS${NC}\n"

echo -e "${BLUE}[+] /etc/sudoers and /etc/sudoers.d/*:${NC}"
echo -e "${YELLOW}$SUDOERS${NC}\n"

echo -e "${BLUE}[+] Sudo group:${NC}"
echo -e "${YELLOW}$SUDOGROUP${NC}\n"

echo -e "${BLUE}[+] Funny SUIDs:${NC}"
echo -e "${YELLOW}$SUIDS${NC}\n"

echo -e "${BLUE}[+] World Writeable Files:${NC}"
echo -e "${YELLOW}$WORLDWRITEABLES${NC}\n"

echo -e "${GREEN}############# Listening Ports ############${NC}\n"
if [ "$IS_BSD" = true ]; then
    DPRINT netstat -an | grep LISTEN | column -t
elif command -v netstat >/dev/null; then
    DPRINT netstat -tlpn | tail -n +3 | awk '{print $1, $4, $6, $7}' | column -t
elif command -v ss >/dev/null; then
    DPRINT ss -blunt -p | tail -n +2 | awk '{print $1, $5, $7}' | column -t 
else
    echo "Netstat and ss commands do not exist"
fi

echo ""
echo -e "${GREEN}############# SERVICE INFORMATION ############${NC}"
if [ "$IS_ALPINE" = true ]; then
    SERVICES=$( rc-status -s | grep started | awk '{print $1}' )
elif [ "$IS_SLACK" = true ]; then
    SERVICES=$( ls -la /etc/rc.d | grep rwx | awk '{print $9}' ) 
elif [ "$IS_BSD" = true ]; then
    SERVICES=$( service -e )
else
    SERVICES=$( DPRINT systemctl --type=service 2>/dev/null | grep active | awk '{print $1}' || service --status-all 2>/dev/null | grep -E '(+|is running)' )
fi

# -----------------------------
# Function: checkService
# -----------------------------
checkService() {
    serviceList=$1
    serviceToCheckExists=$2
    serviceAlias=$3

    if [ -n "$serviceAlias" ]; then
        if echo "$serviceList" | grep -qi "$serviceAlias\|$serviceToCheckExists" ; then
            echo -e "\n${BLUE}[+] $serviceToCheckExists is on this machine${NC}\n"
            if [ "$IS_BSD" = true ]; then
                if DPRINT netstat -an | grep -i "$serviceAlias\|$serviceToCheckExists" >/dev/null 2>&1 ; then
                    echo -e "Active on port(s): ${YELLOW}$( netstat -an | grep -i "$serviceAlias\|$serviceToCheckExists" | awk '{print $4}' | sed 's/.*://g' | tr '\n' ' ' )${NC}\n"
                fi
            else
                if DPRINT netstat -tlpn | grep -i "$serviceAlias" >/dev/null 2>&1 ; then
                    echo -e "Active on port(s): ${YELLOW}$( netstat -tlpn | grep -i "$serviceAlias\|$serviceToCheckExists" | awk 'BEGIN {ORS=" and "} {print $1, $4}' | sed 's/\(.*\)and /\1\n/')${NC}\n"
                elif DPRINT ss -blunt -p | grep -i "$serviceAlias" >/dev/null 2>&1 ; then
                    echo -e "Active on port(s): ${YELLOW}$( ss -blunt -p | grep -i "$serviceAlias\|$serviceToCheckExists" | awk 'BEGIN {ORS=" and " } {print $1, $5}' | sed 's/\(.*\)and /\1\n/')${NC}\n"
                fi
            fi
        fi
    else
        if echo "$serviceList" | grep -qi "$serviceToCheckExists" ; then
            echo -e "\n${BLUE}[+] $serviceToCheckExists is on this machine${NC}\n"
            if [ "$IS_BSD" = true ]; then
                if DPRINT netstat -an | grep -i "$serviceToCheckExists" >/dev/null 2>&1 ; then
                    echo -e "Active on port(s): ${YELLOW}$( netstat -an | grep -i "$serviceToCheckExists" | awk '{print $4}' | sed 's/.*://g' | tr '\n' ' ' )${NC}\n"
                fi
            else
                if DPRINT netstat -tlpn | grep -i "$serviceToCheckExists" >/dev/null 2>&1 ; then
                    echo -e "Active on port(s): ${YELLOW}$( netstat -tlpn | grep -i "$serviceToCheckExists" | awk 'BEGIN {ORS=" and "} {print $1, $4}' | sed 's/\(.*\)and /\1\n/')${NC}\n"
                elif DPRINT ss -blunt -p | grep -i "$serviceToCheckExists" >/dev/null 2>&1 ; then
                    echo -e "Active on port(s): ${YELLOW}$( ss -blunt -p | grep -i "$serviceToCheckExists" | awk 'BEGIN {ORS=" and " } {print $1,$5}' | sed 's/\(.*\)and /\1\n/')${NC}\n"
                fi
            fi
        fi
    fi
}

# --- Examples of checking for certain services ---
if checkService "$SERVICES" 'ssh' | grep -qi "is on this machine"; then
    checkService "$SERVICES" 'ssh'
    SSH=true
fi

if checkService "$SERVICES" 'docker' | grep -qi "is on this machine"; then
    checkService "$SERVICES" 'docker'
    ACTIVECONTAINERS=$( docker ps 2>/dev/null )
    if [ -n "$ACTIVECONTAINERS" ]; then
        echo "Current Active Containers"
        echo -e "${ORAG}$ACTIVECONTAINERS${NC}\n"
    fi
    ANONMOUNTS=$( docker ps -q 2>/dev/null | xargs -n 1 docker inspect --format '{{if .Mounts}}{{.Name}}: {{range .Mounts}}{{.Source}} -> {{.Destination}}{{end}}{{end}}' 2>/dev/null | grep -vE '^$' | sed 's/^\///g' )
    if [ -n "$ANONMOUNTS" ]; then
        echo "Anonymous Container Mounts (host -> container)"
        echo -e "${ORAG}$ANONMOUNTS${NC}\n"
    fi
    VOLUMES="$( docker volume ls --format "{{.Name}}" 2>/dev/null )"
    if [ -n "$VOLUMES" ]; then
        echo "Volumes"
        for v in $VOLUMES; do
            container=$( docker ps -a --filter volume=$v --format '{{.Names}}' 2>/dev/null | tr '\n' ',' | sed 's/,$//g' )
            if [ -n "$container" ]; then
                mountpoint=$( docker volume inspect --format '{{.Name}}: {{.Mountpoint}}' $v 2>/dev/null | awk -F ': ' '{print $2}' )
                echo -e "${ORAG}$v -> $mountpoint used by $container${NC}"
            fi
        done
        echo ""
    fi
fi

if checkService "$SERVICES" 'cockpit' | grep -qi "is on this machine"; then
    checkService "$SERVICES" 'cockpit'
    echo -e "${ORAG}[!] WE PROBABLY SHOULD KILL COCKPIT${NC}"
fi

if checkService "$SERVICES" 'apache2' | grep -qi "is on this machine"; then
    checkService "$SERVICES" 'apache2'
    APACHE2VHOSTS=$( tail -n +1 /etc/apache2/sites-enabled/* 2>/dev/null | grep -v '#' | grep -E '==>|VirtualHost|^[[:space:]]*ServerName|DocumentRoot|^[[:space:]]*ServerAlias|^[[:space:]]*Proxy' )
    echo -e "\n[!] Configuration Details\n"
    echo -e "${ORAG}$APACHE2VHOSTS${NC}"
    APACHE2=true
fi

if checkService "$SERVICES" 'ftp' | grep -qi "is on this machine"; then
    checkService "$SERVICES" 'ftp'
    FTPCONF=$( cat /etc/*ftp* 2>/dev/null | grep -v '#' | grep -E 'anonymous_enable|guest_enable|no_anon_password|write_enable' )
    echo -e "\n[!] Configuration Details\n"
    echo -e "${ORAG}$FTPCONF${NC}"
fi

if checkService "$SERVICES" 'nginx' | grep -qi "is on this machine"; then
    checkService "$SERVICES" 'nginx'
    NGINXCONFIG=$( tail -n +1 /etc/nginx/sites-enabled/* 2>/dev/null | grep -v '#' | grep -E '==>|server|^[[:space:]]*listen|^[[:space:]]*root|^[[:space:]]*server_name|proxy_' )
    echo -e "\n[!] Configuration Details\n"
    echo -e "${ORAG}$NGINXCONFIG${NC}"
    NGINX=true
fi

# Additional service and SQL checks would follow here...
# (Ensure that any Linux-specific commands are similarly branched for BSD if needed)

# (The script appears to be truncated; add any additional service checks below as required.)

