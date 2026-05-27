$compName = (cmd.exe /c hostname)
$LogPath = Join-Path $PSScriptRoot "ShutdownLog-$compName.txt"

Get-WinEvent -FilterHashtable @{
    LogName = 'System'
    Id      = 41, 1074, 6006, 6605, 6008
} |
Format-List Id, LevelDisplayName, TimeCreated, Message |
Out-String |
ForEach-Object { $_.Trim() } |
Out-File $LogPath

Start-Process $LogPath
