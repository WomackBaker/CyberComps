Import-Module ActiveDirectory

$DomainUsers = Get-ADUser -Filter * -Properties SamAccountName
$LocalUsers = Get-LocalUser | Where-Object { $_.PrincipalSource -eq "Local" }

$Blacklist = @("username1", "username2")
function New-Password {
    $PasswordLength = 23
    $PasswordChars = "abcdefghijkmnopqrstuvwxyzABCDEFGHJKLMNOPQRSTUVWXYZ0123456789@#$%&!?:*-+="
    $Password = ""
    For ($i = 0; $i -lt $PasswordLength; $i++) {
        $RandomChar = Get-Random -Maximum $PasswordChars.Length
        $Password += $PasswordChars[$RandomChar]
    }
    return $Password
}

Write-Output "Printing domain users:"
foreach ($User in $DomainUsers) {
    if ($User.SamAccountName -notin $Blacklist) {
        $NewPassword = New-Password
        Set-ADAccountPassword -Identity $User -NewPassword (ConvertTo-SecureString -AsPlainText $NewPassword -Force)
        Write-Output "$($User.SamAccountName),$NewPassword"
    }
}

Write-Output "Printing local users:"
foreach ($User in $LocalUsers) {
    if ($User.SamAccountName -notin $Blacklist) {
    $NewPassword = New-Password
    Set-LocalUser -Name $User.Name -Password (ConvertTo-SecureString $NewPassword -AsPlainText -Force) | Out-Null
    Write-Output "$($User.Name),$NewPassword"
    }
}
