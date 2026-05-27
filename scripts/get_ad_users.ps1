$compName = (cmd.exe /c hostname)

$LogPath = Join-Path $PSScriptRoot "ADUsers-$compName.csv"

$Users = Get-ADUser -filter * -Properties Name, DisplayName, userPrincipalName, Enabled, whenCreated, whenChanged, AccountExpirationDate, lastLogon, description, DistinguishedName | Select-Object Name, DisplayName, userPrincipalName, Enabled, whenCreated, whenChanged, AccountExpirationDate, @{Name = "lastLogon"; Expression = { if ($_.lastLogon -ne "" -and $null -ne $_.lastLogon) { [datetime]::FromFileTime($_.lastLogon) } } }, description, DistinguishedName
$Users | Export-Csv $LogPath -NoTypeInformation -Encoding UTF8

Start-Process $LogPath