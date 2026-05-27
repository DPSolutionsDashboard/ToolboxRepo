# ============================================
# DATTO RMM REINSTALLER (TECH‑FRIENDLY VERSION)
# ============================================

Add-Type -AssemblyName Microsoft.VisualBasic

# Prompt tech for Site ID
$SiteId = [Microsoft.VisualBasic.Interaction]::InputBox(
    "Enter Site ID for Datto RMM Installer:",
    "Datto RMM Reinstall",
    ""
)

if (-not $SiteId -or $SiteId -eq "") {
    Write-Output "[ERROR] No Site ID entered. Exiting."
    exit 1
}

$ProgramName = "Datto RMM"
$DownloadPath = "C:\Temp"
$InstallerPath = Join-Path $DownloadPath "AgentInstall.exe"
$DownloadUrl = "https://vidal.rmm.datto.com/download-agent/windows/$SiteId"

Write-Output "[INFO] Using Site ID: $SiteId"
Write-Output "[INFO] Downloading installer from: $DownloadUrl"

# Ensure temp folder exists
if (!(Test-Path $DownloadPath)) {
    New-Item -ItemType Directory -Path $DownloadPath | Out-Null
}

# Download installer
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$ProgressPreference = 'SilentlyContinue'

try {
    Invoke-WebRequest -Uri $DownloadUrl -OutFile $InstallerPath -ErrorAction Stop
}
catch {
    Write-Output "[WARN] Failed to download installer: $($_.Exception.Message)"
    exit 1
}

if (!(Test-Path $InstallerPath)) {
    Write-Output "[ERROR] Installer missing after download."
    exit 1
}

Write-Output "[INFO] Installer downloaded successfully."

# ----------------------------
# Helper: Stop processes
# ----------------------------
function Stop-Proc($name) {
    Get-Process -Name "$name*" -ErrorAction SilentlyContinue |
    ForEach-Object {
        Write-Output "[INFO] Stopping process: $($_.ProcessName)"
        Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue
    }
}

# ----------------------------
# Helper: Remove folders
# ----------------------------
function Remove-Fold($path) {
    if (Test-Path $path) {
        Remove-Item $path -Recurse -Force -ErrorAction SilentlyContinue
        if (!(Test-Path $path)) {
            Write-Output "[INFO] Removed folder: $path"
        }
    }
}

# ----------------------------
# Helper: Remove registry keys
# ----------------------------
function Remove-Reg($key) {
    if (Get-Item $key -ErrorAction SilentlyContinue) {
        Remove-Item $key -Recurse -Force -ErrorAction SilentlyContinue
        if (!(Get-Item $key -ErrorAction SilentlyContinue)) {
            Write-Output "[INFO] Removed registry key: $key"
        }
    }
}

# ----------------------------
# Uninstall existing Datto RMM
# ----------------------------
Write-Output "[INFO] Checking for existing Datto RMM installation..."

$uninstallStrings = Get-ChildItem HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall,
HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall |
Get-ItemProperty |
Where-Object { $_.DisplayName -match $ProgramName } |
Select-Object -ExpandProperty UninstallString -ErrorAction SilentlyContinue

if ($uninstallStrings) {
    foreach ($cmd in $uninstallStrings) {
        $clean = $cmd -replace "\s{2,}", " "
        Write-Output "[INFO] Running uninstall: $clean /S"
        Start-Process -FilePath $clean -ArgumentList "/S" -Wait
    }
}
else {
    Write-Output "[INFO] Datto RMM not currently installed."
}

# ----------------------------
# Cleanup old artifacts
# ----------------------------
Stop-Proc "AEMAgent"
Stop-Proc "CagService"

Remove-Fold "C:\Program Files (x86)\CentraStage"
Remove-Fold "C:\ProgramData\CentraStage"
Remove-Fold "C:\Windows\System32\config\systemprofile\AppData\Local\CentraStage"
Remove-Fold "C:\Windows\SysWOW64\config\systemprofile\AppData\Local\CentraStage"

Remove-Reg "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Run\CentraStage"
Remove-Reg "HKCU:\cag"

# ----------------------------
# Install new agent
# ----------------------------
Write-Output "[INFO] Installing Datto RMM..."
Start-Process -FilePath $InstallerPath -ArgumentList "/S" -Wait

# ----------------------------
# Verify install
# ----------------------------
Start-Sleep -Seconds 30
$verify = Get-ChildItem HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall,
HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall |
Get-ItemProperty |
Where-Object { $_.DisplayName -match $ProgramName }

if ($verify) {
    Write-Output "[INFO] Successfully installed Datto RMM."
    exit 0
}

Write-Output "[WARN] Failed to install Datto RMM."
exit 1