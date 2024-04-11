# CyberComps

# Linux Scripts

01 - # Script runs and only allows certain ports
    - ./script <port1> <port2> <port3>

02 - # Find users with shell and allows certain ones
    - ./script # ADD USER TO ALLOW LIST name1 name2 name3

03 - # USED TO CREATE RSA KEY - DONT NEED TO RUN

04 - # Runs bashkiller, checking for current users, and rev shell

05 - # Enumerates and removse dangerous SUID binaries

06 - # Erases all current crontabs

07 - # SSH Securing

08 - # Process monitor adding logging

09 - # Install Snoopy - command logger 

10 - # More linux hardening

11 - # Reverse shell checker

12 - # Context on system, grabs all services, service info 

# Windows

- hardeningKitty.ps1 - Runs hardening kitty

- SMB.bat - Secures SMB

- ServiceMonitor.ps1 - Actively monitors and allows user to kill/not kill

- Log.ps1 - Starts logging

- hardenOS.bat - General Hardening

- harden.ps1 - Mainly updates Windows

- Gpo.ps1 - Grabs GPO

- gatherContext.ps1 - Checks for users *Need to update user list*

- Fix.ps1 - Restores original group policy

- Exec.ps1 - Prints anything executed

- dcFirewall.bat - Sets firewall rules

- Comp.ps1 - Prints password changes, share access, and password changes

- checkServices.ps1 - Checks on sus services

- auditingOn.ps1 - Enables auditing

- getallusers.ps1 - Gets all domain and local users

- passchangeAll.ps1 - Changes passwords to all in this format *user,password*