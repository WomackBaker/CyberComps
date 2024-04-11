# Linux System Administration and Security Commands Documentation

## File and Directory Operations
- Securely Copy Directories:  
  scp -r /path/to/local/directory remote_username@remote_host:/path/to/remote/directory
- Change All Text Files from CRLF to LF:  
  dos2unix *
- Change Permissions of Directories:  
  chmod 700 "/path to file"
  chmod -f 0700 /home/*
  chmod -f 0700 /export/home/*

## User Management
- List All Active Users:  
  who
- Change Root and User Password:  
  passwd "user"
- Delete Users:  
  userdel -f "user" 2>/dev/null

## Network and Process Management
- List Open Files and Processes by Port:  
  sudo lsof -i :22
- Block an IP Address with iptables:  
  sudo iptables -A INPUT -s $ip -j DROP
- Allow and Block Ports Using iptables:  
  sudo iptables -I INPUT -p tcp --dport $port -j ACCEPT
  sudo iptables -I OUTPUT -p tcp --sport $port -j ACCEPT
  sudo iptables -A INPUT -j DROP
  sudo iptables -A OUTPUT -j DROP
- Kill and Manage Jobs:  
  kill %1
  ./pkillbash.sh &
  sudo pkill -u <your_username>
- Check for Outbound Connections:  
  netstat -anp | grep ESTABLISHED

## Database Management
- MySQL User Management:  
  SELECT User, Host FROM mysql.user;
  ALTER USER 'username'@'localhost' IDENTIFIED BY 'newpassword';

## Security Enhancements
- Fail2Ban Unban IP:  
  sudo fail2ban-client set sshd unbanip 192.168.1.100
- Linux Kernel Hardening and Packet Management:  
  Various sed and echo commands to modify system configuration for security.
- Remove Risky Packages:  
  Various apt-get remove commands to uninstall potentially insecure software.
- SSH Security Enhancements:  
  Remove and configure SSH settings to improve security.

## Windows Administration Commands
- Change Passwords:  
  PowerShell commands to reset passwords for local and domain users.
- Manage SMB Versions:  
  PowerShell commands to enable and disable specific SMB protocols.
- Remote Desktop Protocol (RDP) Configuration:  
  Procedures to manage and secure RDP settings.

## Additional Notes
- Check Programs with Root Access:  
  find / -perm -04000 > programsWithRootAccess.txt
- Inspect Network Packets for Anomalies:  
  Packet Inspect for anything suspicious
- System Updates:  
  Commands to update and upgrade system packages.

## Resources
- Securing Basic Linux: https://github.com/Techryptic/Cyber-Defense-Competition-Scripts/blob/master/ubuntu_ftp_secure.sh
- Iptables Scripts: https://github.com/CyberLions/CCDC/tree/master/2024/iptables%20Scripts
- Fenrir IOC Scanner: https://github.com/Neo23x0/Fenrir
