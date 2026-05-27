$compName = (cmd.exe /c hostname)

$path = "C:\temp\Logs"
if (!(Test-Path -PathType container $path)) {
    New-Item -ItemType Directory -Path $path -Force | Out-Null
}

$LogPath = "$path\ADComputers-$compName.csv"
if (Test-Path -LiteralPath "$LogPath" -PathType Leaf) {
    Remove-Item -LiteralPath "$LogPath" -Force | Out-Null
}

$Users = Get-ADComputer -filter * -Properties Name, whenCreated, whenChanged, lastLogon, operatingSystem, description, DistinguishedName | Select-Object Name, whenCreated, whenChanged, @{Name = "lastLogon"; Expression = { if ($_.lastLogon -ne "" -and $null -ne $_.lastLogon) { [datetime]::FromFileTime($_.lastLogon) } } }, operatingSystem, description, DistinguishedName
$Users | Export-Csv $LogPath -NoTypeInformation

if (Test-Path -LiteralPath "$LogPath" -PathType Leaf) {
    Write-Output "$LogPath created successfully."
}