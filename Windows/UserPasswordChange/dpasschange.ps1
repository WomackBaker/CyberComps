#Script grabs ONLY DOMAIN USERS and changes their passwords, then outputs a csv file with the username and password
Import-Module ActiveDirectory

$DomainUsers = Get-ADUser -Filter *
$PrintDomainUsers=@()

function New-Password {
    $PasswordLength = 23
    $PasswordChars = "abcdefghijkmnopqrstuvwxyzABCDEFGHJKLMNOPQRSTUVWXYZ0123456789@#$%&!?:*-+="
    $Password = ""
    For ($i=0; $i -lt $PasswordLength; $i++) {
        $RandomChar = Get-Random -Maximum $PasswordChars.Length
        $Password += $PasswordChars[$RandomChar]
    }
    return $Password
}

foreach ($User in $DomainUsers) {
    $NewPassword = New-Password
    Set-ADAccountPassword -Identity $User -NewPassword (ConvertTo-SecureString -AsPlainText $newPassword -Force)
    $PrintDomainUsers += [PSCustomObject]@{
        UserName = $User
        Password = $NewPassword
    }
}
Write-Output "Printing domain users:"
$PrintDomainUsers | ForEach-Object { "$($_.UserName),$($_.Password)" }