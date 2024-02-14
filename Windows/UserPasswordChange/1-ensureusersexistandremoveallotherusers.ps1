$usersToKeep = @(
    "Guest", "Administrator"
)

# get all local user accounts
$allUsers = Get-LocalUser | Where-Object { $_.PrincipalSource -eq "Local" }

foreach ($user in $allUsers) {
    if ($user.Name -notin $usersToKeep) {
        # attempt to delete the user, ignoring any errors (e.g., system accounts)
        try {
            Remove-LocalUser -Name $user.Name -ErrorAction Stop
            Write-Output "Deleted user: $($user.Name)"
        } catch {
            Write-Warning "Could not delete user: $($user.Name). Error: $_"
        }
    }
}

# get all domain user accounts
$allDomainUsers = Get-ADUser -Filter *

foreach ($user in $allDomainUsers) {
    $username = $user.SamAccountName

    if ($usersToKeep -notcontains $username) {
	# attempt to delete the user, ignoring any errors
        try {
	    Remove-ADUser -Identity $username -Confirm:$false -ErrorAction Stop
	    Write-Output "Deleted user: $username"
	} catch {
	    Write-Output "Could not delete user: $($username). Error: $_"
	}
    }
}