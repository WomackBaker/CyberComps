# Define user arrays
$normalUsers = @(
"lucy.nova", "xavier.blackhole", "ophelia.redding", "marcus.atlas",
"yara.nebula", "parker.posey", "maya.star", "zachary.comet",
"quinn.jovi", "nina.eclipse", "alice.bowie", "ruby.rose",
"owen.mars", "bob.dylan", "samantha.stephens", "parker.jupiter",
"carol.rivers", "taurus.tucker", "rachel.venus", "emily.waters",
"una.veda", "ruby.starlight", "frank.zappa", "ava.stardust",
"samantha.aurora", "grace.slick", "benny.spacey", "sophia.constellation",
"harry.potter", "celine.cosmos", "tessa.nova", "ivy.lee",
"dave.marsden", "thomas.spacestation", "kate.bush", "emma.nova",
"una.moonbase", "luna.lovegood", "frank.astro", "victor.meteor",
"mars.patel", "grace.luna", "wendy.starship", "neptune.williams",
"henry.orbit", "ivy.starling"
)

$administratorGroup = @(
"elara.boss", "sarah.lee", "lisa.brown", "michael.davis",
"emily.chen", "tom.harris", "bob.johnson", "david.kim",
"rachel.patel", "dave.grohl", "kate.skye", "leo.zenith",
"jack.rover"
)

$DONOTTOUCH = @(
"seccdc_black"
)

# Create or clear the file at the beginning
$contextPath = "context.txt"
if (Test-Path $contextPath) { Clear-Content $contextPath }

# System information gathering
Add-Content $contextPath -Value "[OS]"
Add-Content $contextPath -Value (Get-CimInstance Win32_OperatingSystem | Format-List * | Out-String)

Add-Content $contextPath -Value "[Hostname]"
Add-Content $contextPath -Value ($env:COMPUTERNAME)

Add-Content $contextPath -Value "[Admins]"
$admins = Get-LocalGroupMember -Group "Administrators" | Select-Object -ExpandProperty Name
foreach ($admin in $admins) {
    Add-Content $contextPath -Value $admin
}

Add-Content $contextPath -Value "[Users]"
$users = Get-LocalUser | Select-Object -ExpandProperty Name
foreach ($user in $users) {
    Add-Content $contextPath -Value $user
}

Add-Content $contextPath -Value "[IP/MAC]"
Get-NetIPAddress | Where-Object { $_.AddressFamily -eq "IPv4" } | Format-Table -Property IPAddress, InterfaceAlias, InterfaceIndex | Out-String | ForEach-Object { Add-Content $contextPath -Value $_ }

Add-Content $contextPath -Value "[Routes]"
Get-NetRoute | Format-Table -Property DestinationPrefix, NextHop, RouteMetric, InterfaceIndex | Out-String | ForEach-Object { Add-Content $contextPath -Value $_ }

Add-Content $contextPath -Value "[Services]"
Get-Service | Format-Table -Property Name, DisplayName, Status | Out-String | ForEach-Object { Add-Content $contextPath -Value $_ }

# Check for unauthorized users
$allUsers = Get-LocalUser | Select-Object -ExpandProperty Name
$unauthorizedUsers = $allUsers | Where-Object { $_ -notin $normalUsers -and $_ -notin $administratorGroup -and $_ -notin $DONOTTOUCH }

$unauthorizedAdmins = $admins | Where-Object { $_ -notin $administratorGroup }

# Alert for unauthorized users
if ($unauthorizedUsers.Count -gt 0) {
    $alertMessage = "ALERT: A USER HAS BEEN DETECTED THAT IS NOT AUTHORIZED: $($unauthorizedUsers -join ', ')"
    Add-Content $contextPath -Value $alertMessage
    Write-Host $alertMessage
}

# Alert for unauthorized admins
if ($unauthorizedAdmins.Count -gt 0) {
    $alertMessage = "ALERT: UNAUTHORIZED ADMINISTRATOR DETECTED: $($unauthorizedAdmins -join ', ')"
    Add-Content $contextPath -Value $alertMessage
    Write-Host $alertMessage
}

# Output the contents of context.txt to the terminal
Get-Content -Path $contextPath | Write-Output