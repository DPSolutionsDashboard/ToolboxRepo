$date = Get-Date
$maxdate = $date.AddDays(14)
$mindate = $date.AddDays(-365)
Get-ADGroupMember -Identity "Domain Users" | ForEach-Object {
    Get-ADUser -Identity $_.SamAccountName -Properties Enabled, PasswordNeverExpires, "DisplayName", emailaddress, "msDS-UserPasswordExpiryTimeComputed" | Select-Object -Property Enabled, PasswordNeverExpires, "Displayname", emailaddress, @{Name = "ExpiryDate"; Expression = { [datetime]::FromFileTime($_."msDS-UserPasswordExpiryTimeComputed") } } | Where-Object { $_.ExpiryDate -le "$maxdate" -and $_.ExpiryDate -ge "$mindate" -and $_.emailaddress -ne $null -and $_.Enabled -eq $True -and $_.PasswordNeverExpires -eq $False } | ForEach-Object {
        $email = $_.emailaddress
        $expire = $_.ExpiryDate
        $name = $_.Displayname
        Write-Output "[INFO] $name - $email password expires on $expire"
    }
}