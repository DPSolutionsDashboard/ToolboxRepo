$compName = (cmd.exe /c hostname)

$LogPath = Join-Path $PSScriptRoot "ADComputers-$compName.csv"

$Users = Get-ADComputer -filter * -Properties Name, whenCreated, whenChanged, lastLogon, pwdLastSet, operatingSystem, description, DistinguishedName | Select-Object Name, whenCreated, whenChanged, @{Name = "lastLogon"; Expression = { if ($_.lastLogon -ne "" -and $null -ne $_.lastLogon) { [datetime]::FromFileTime($_.lastLogon) } } }, @{Name = "pwdLastSet"; Expression = { if ($_.pwdLastSet -ne "" -and $null -ne $_.pwdLastSet) { [datetime]::FromFileTime($_.pwdLastSet) } } }, operatingSystem, description, DistinguishedName
$Users | Export-Csv -Path "$LogPath" -NoTypeInformation -Encoding UTF8

Start-Process $LogPath