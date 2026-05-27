$agentVer = ((Get-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Services\SentinelAgent\).ImagePath)
$s1folder = ("$agentVer" -split '[\\]')[-2]
$s1ctl = "C:\Program Files\SentinelOne\$s1folder\SentinelCtl.exe"
if (Test-Path -LiteralPath "$s1ctl" -PathType Leaf -ErrorAction SilentlyContinue) {
    Write-Output "[INFO] Loading agent."
    & $s1ctl load -a
}
else {
    Write-Output "[ERROR] File Missing: $s1ctl"
}