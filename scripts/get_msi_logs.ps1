$compName = (cmd.exe /c hostname)
$LogPath = Join-Path $PSScriptRoot "MSILogs-$compName.txt"
Get-WinEvent -FilterHashtable @{ LogName = 'Application'; ProviderName = "MsiInstaller"; } | Format-List Id, LevelDisplayName, TimeCreated, Message | Out-String | ForEach-Object { $_.trim() } | Out-File "$LogPath"
Start-Process $LogPath