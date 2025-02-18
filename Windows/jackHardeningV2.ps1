# ======================================
# 1. System Information Gathering
# ======================================

$hostname = (Get-WmiObject -Class Win32_ComputerSystem).Name
$domain = (Get-WmiObject -Class Win32_ComputerSystem).Domain
$ip = (Get-WmiObject Win32_NetworkAdapterConfiguration | Where-Object {$_.IpAddress -ne $null} | Select-Object -ExpandProperty IpAddress)

Write-Output "Hostname: $hostname"
Write-Output "Domain: $domain"
Write-Output "IP Address: $ip"

# ======================================
# 2. Prevent Auto-Reboots
# ======================================

reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update" /v NoAutoRebootWithLoggedOnUsers /t REG_DWORD /d 1 /f

# ======================================
# 3. Backup Pre-Hardening State
# ======================================

Enable-ComputerRestore -Drive "C:\"; Start-Sleep -Seconds 5
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore" /v SystemRestorePointCreationFrequency /t REG_DWORD /d 0 /f
Checkpoint-Computer -Description "Pre-Hardening Backup" -RestorePointType MODIFY_SETTINGS

# ======================================
# 4. User Account Hardening
# ======================================

# Disable Guest and built-in Administrator accounts
net user Administrator /active:no
net user Guest /active:no
net user DefaultAccount /active:no
net user WDAGUtilityAccount /active:no

# Rename Administrator Account (Uncomment and Set Desired Name)
# WMIC USERACCOUNT WHERE Name='Administrator' CALL Rename Name='Admin'

# ======================================
# 5. Registry Security Hardening
# ======================================

# Disable LM Hash Storage
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" /v NoLmHash /t REG_DWORD /d 1 /f

# Disable WDigest Plaintext Credential Storage
reg add "HKLM\SYSTEM\CurrentControlSet\Control\SecurityProviders\WDigest" /v UseLogonCredential /t REG_DWORD /d 0 /f

# Enable LSASS Protection
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" /v RunAsPPL /t REG_DWORD /d 1 /f

# Enforce UAC Policies
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v EnableLUA /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v ConsentPromptBehaviorAdmin /t REG_DWORD /d 2 /f
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v PromptOnSecureDesktop /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v EnableInstallerDetection /t REG_DWORD /d 1 /f

# Disable Anonymous Enumeration
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" /v restrictanonymous /t REG_DWORD /d 1 /f
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" /v restrictanonymoussam /t REG_DWORD /d 1 /f
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" /v everyoneincludesanonymous /t REG_DWORD /d 0 /f

# Enable Credential Guard
reg add "HKLM\SYSTEM\CurrentControl\Control\Lsa" /v LsaCfgFlags /t REG_DWORD /d 1 /f

# ======================================
# 6. Attack Surface Reduction Rules (ASR)
# ======================================

$asrRules = @(
    "75668C1F-73B5-4CF0-BB93-3ECF5CB7CC84", # Block Office apps from injecting into processes
    "3B576869-A4EC-4529-8536-B80A7769E899", # Block Office apps from creating executables
    "D4F940AB-401B-4EfC-AADC-AD5F3C50688A", # Block all Office apps from creating child processes
    "D3E037E1-3EB8-44C8-A917-57927947596D", # Block JavaScript from executing downloaded content
    "5BEB7EFE-FD9A-4556-801D-275E5FFC04CC", # Block obfuscated scripts
    "BE9BA2D9-53EA-4CDC-84E5-9B1EEEE46550", # Block executable content from email/webmail
    "9E6C4E1F-7D60-472F-BA1A-A39EF669E4B2"  # Block credential stealing from LSASS
)
foreach ($rule in $asrRules) {
    Add-MpPreference -AttackSurfaceReductionRules_Ids $rule -AttackSurfaceReductionRules_Actions Enabled
}

# ======================================
# 7. Service Lockdown
# ======================================

# Disable Print Spooler
net stop spooler
sc.exe config spooler start=disabled

# Disable BITS Transfers (Prevent Abuse)
reg add "HKLM\Software\Policies\Microsoft\Windows\BITS" /v EnableBITSMaxBandwidth /t REG_DWORD /d 0 /f

# ======================================
# 8. Security Updates
# ======================================

#Write-Output "Updating System and Configuring Defender..."
# Install Windows Updates
#$updateSession = New-Object -ComObject Microsoft.Update.Session
#$updateSearcher = $updateSession.CreateUpdateSearcher()
#$searchResult = $updateSearcher.Search("IsInstalled=0")
#$updatesToInstall = New-Object -ComObject Microsoft.Update.UpdateColl
#foreach ($update in $searchResult.Updates) {
#    if ($update.IsDownloaded) {
#        $updatesToInstall.Add($update) | Out-Null
#    }
#}
#$installer = $updateSession.CreateUpdateInstaller()
#$installer.Updates = $updatesToInstall
#$installer.Install()
#Write-Output "Windows Updates Installed."

# ======================================
# 9. Defender Configuration
# ======================================

Set-MpPreference -DisableRealtimeMonitoring $false
Set-NetFirewallProfile -Profile Domain -Enabled True
Set-NetFirewallProfile -Profile Private -Enabled True
Set-NetFirewallProfile -Profile Public -Enabled True

# ======================================
# 10. Backup Post-Hardening State
# ======================================
Checkpoint-Computer -Description "Pre-HardeningKitty Backup" -RestorePointType MODIFY_SETTINGS

# ======================================
# 11. Install and Run HardeningKitty
# ======================================

Function InstallHardeningKitty() {
    $Version = (((Invoke-WebRequest "https://api.github.com/repos/scipag/HardeningKitty/releases/latest" -UseBasicParsing) | ConvertFrom-Json).Name).SubString(2)
    $HardeningKittyLatestVersionDownloadLink = ((Invoke-WebRequest "https://api.github.com/repos/scipag/HardeningKitty/releases/latest" -UseBasicParsing) | ConvertFrom-Json).zipball_url
    $ProgressPreference = 'SilentlyContinue'
    Invoke-WebRequest $HardeningKittyLatestVersionDownloadLink -Out HardeningKitty$Version.zip
    Expand-Archive -Path ".\HardeningKitty$Version.zip" -Destination ".\HardeningKitty$Version" -Force
    $Folder = Get-ChildItem .\HardeningKitty$Version | Select-Object Name -ExpandProperty Name
    Move-Item ".\HardeningKitty$Version\$Folder\*" ".\HardeningKitty$Version\"
    Remove-Item ".\HardeningKitty$Version\$Folder\"
    New-Item -Path $Env:ProgramFiles\WindowsPowerShell\Modules\HardeningKitty\$Version -ItemType Directory
    Set-Location .\HardeningKitty$Version
    Copy-Item -Path .\HardeningKitty.psd1,.\HardeningKitty.psm1,.\lists\ -Destination $Env:ProgramFiles\WindowsPowerShell\Modules\HardeningKitty\$Version\ -Recurse
    Import-Module "$Env:ProgramFiles\WindowsPowerShell\Modules\HardeningKitty\$Version\HardeningKitty.psm1"
}

InstallHardeningKitty

Invoke-HardeningKitty -Mode Config -Backup

Invoke-HardeningKitty -EmojiSupport

#Invoke-HardeningKitty -Mode HailMary -Log -Report -FileFindingList finding_list_0x6d69636b_machine.csv