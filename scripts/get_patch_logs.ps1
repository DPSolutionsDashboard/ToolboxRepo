$compName = (cmd.exe /c hostname)

$LogPath = Join-Path $PSScriptRoot "PatchLog-$compName.csv"

$Session = New-Object -ComObject "Microsoft.Update.Session"
$Searcher = $Session.CreateUpdateSearcher()

$historyCount = $Searcher.GetTotalHistoryCount()

$Searcher.QueryHistory(0, $historyCount) | Select-Object Date, ClientApplicationID, Title, Description, SupportUrl, UninstallationNotes, ServerSelection | Export-Csv -Path "$LogPath" -NoTypeInformation -Encoding UTF8

Start-Process $LogPath