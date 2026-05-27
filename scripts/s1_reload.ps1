Add-Type -AssemblyName Microsoft.VisualBasic
$agentVer = ((Get-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Services\SentinelAgent\).ImagePath)
$s1folder = ("$agentVer" -split '[\\]')[-2]
$s1ctl = "C:\Program Files\SentinelOne\$s1folder\SentinelCtl.exe"
if (Test-Path -LiteralPath "$s1ctl" -PathType Leaf -ErrorAction SilentlyContinue) {
    $passphrase = [Microsoft.VisualBasic.Interaction]::InputBox("SentinelOne Passphrase:", "SentinelOne Passphrase", "")
    if ($null -ne $passphrase -and $passphrase -ne "") {
        Write-Output "[INFO] Reloading agent with passphrase."
        & $s1ctl reload -a -k "$passphrase"
    }
     else {
        Write-Output "[WARN] No passphrase supplied. Attempting to reload without passphrase."
        & $s1ctl reload -a
    }
}
else {
    Write-Output "[ERROR] File Missing: $s1ctl"
}
