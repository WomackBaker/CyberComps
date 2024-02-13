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

# Note: Invoke-HardeningKitty -Mode HailMary -Log -Report -FileFindingList finding_list_0x6d69636b_machine.csv 
# HardeningKitty uses an output file, use the below code block to create a backup, and a findings list, and then run it with
# Note, it does not harden by default. You can have it harden below, where “finding_list” is the file corresponding to the OS in the ./lists directory it creates. Refer to the github page for more details.
# https://github.com/scipag/HardeningKitty