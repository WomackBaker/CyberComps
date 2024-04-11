Import-Module ActiveDirectory

# Define admin groups
$adminGroups = @("Domain Admins", "Enterprise Admins", "Administrators")

# Find all users
$allUsers = Get-ADUser -Filter * -Property MemberOf

# Initialize arrays to hold admins and normal users
$admins = @()
$normalUsers = @()

foreach ($user in $allUsers) {
    # Check if the user is a member of any admin group
    $isAdmin = $false
    foreach ($group in $adminGroups) {
        $groupDN = (Get-ADGroup $group).DistinguishedName
        if ($user.MemberOf -contains $groupDN) {
            $isAdmin = $true
            break
        }
    }
    
    if ($isAdmin) {
        $admins += $user
    } else {
        $normalUsers += $user
    }
}

# Outputting the results
Write-Output "Admins:"
$admins | ForEach-Object { Write-Output $_.SamAccountName }

Write-Output "Normal Users:"
$normalUsers | ForEach-Object { Write-Output $_.SamAccountName }
