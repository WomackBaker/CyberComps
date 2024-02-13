# PowerShell Script to Automatically Install Windows Updates

$updateSession = New-Object -ComObject Microsoft.Update.Session
$updateSearcher = $updateSession.CreateUpdateSearcher()

Write-Host "Searching for updates..."
$searchResult = $updateSearcher.Search("IsInstalled=0")

if ($searchResult.Updates.Count -eq 0) {
    Write-Host "There are no applicable updates."
    exit
}

$updatesToDownload = New-Object -ComObject Microsoft.Update.UpdateColl
foreach ($update in $searchResult.Updates) {
    $updatesToDownload.Add($update) | Out-Null
}

$downloader = $updateSession.CreateUpdateDownloader()
$downloader.Updates = $updatesToDownload
$downloadResult = $downloader.Download()
Write-Host "Download of updates: $($downloadResult.ResultCode)"

$updatesToInstall = New-Object -ComObject Microsoft.Update.UpdateColl
foreach ($update in $searchResult.Updates) {
    if ($update.IsDownloaded) {
        $updatesToInstall.Add($update) | Out-Null
    }
}

$installer = $updateSession.CreateUpdateInstaller()
$installer.Updates = $updatesToInstall
$installationResult = $installer.Install()

Write-Host "Installation Result: $($installationResult.ResultCode)"
Write-Host "Reboot Required: $($installationResult.RebootRequired)"

foreach ($update in $installationResult.Updates) {
    Write-Host "Installed: $($update.Title)"
}


$downloadUrl = "https://downloads.malwarebytes.com/file/mb4_offline"

$installerPath = "$env:TEMP\mb-setup.exe"

Invoke-WebRequest -Uri $downloadUrl -OutFile $installerPath

Start-Process -FilePath $installerPath -Args "/verysilent /norestart" -Wait -NoNewWindow

Remove-Item -Path $installerPath

Write-Host "Malwarebytes installation completed."

Set-MpPreference -DisableRealtimeMonitoring $false; Set-NetFirewallProfile -Profile Domain -Enabled True; Set-NetFirewallProfile -Profile Private -Enabled True; Set-NetFirewallProfile -Profile Public -Enabled True

Set-Processmitigation -System -Enable DEP,EmulateAtlThunks,BottomUp,HighEntropy,SEHOP,SEHOPTelemetry,TerminateOnError