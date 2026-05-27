Add-Type -AssemblyName System.Windows.Forms
$msgBoxInput = [System.Windows.Forms.MessageBox]::Show('Would you like to rebind Sentinel Agent?', 'Rebind Sentinel Agent', 'YesNo')
switch ($msgBoxInput) {
    'Yes' {
        if ($null -ne $sitetoken -and $sitetoken -ne "") {
            $agentVer = ((Get-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Services\SentinelAgent\).ImagePath)
            $s1folder = ("$agentVer" -split '[\\]')[-2]
            $s1ctl = "C:\Program Files\SentinelOne\$s1folder\SentinelCtl.exe"
            if (Test-Path -LiteralPath "$s1ctl" -PathType Leaf -ErrorAction SilentlyContinue) {
                Add-Type -AssemblyName Microsoft.VisualBasic
                $sitetoken = [Microsoft.VisualBasic.Interaction]::InputBox("Enter Site Token", "SentinelOne Site Token", "")
                $msgBoxInput2 = [System.Windows.Forms.MessageBox]::Show('Do you have the Passphrase?', 'Rebind Sentinel Agent', 'YesNo')
                switch ($msgBoxInput2) {
                    'Yes' {
                        $passphrase = [Microsoft.VisualBasic.Interaction]::InputBox("Enter PassPhrase", "SentinelOne PassPhrase", "")
                        if ($null -ne $passphrase -and $passphrase -ne "") {
                            Write-Output "[INFO] Rebinding Sentinel Agent with site token and passphrase."
                            & $s1ctl bind "$sitetoken" -k "$passphrase"
                            & $s1ctl reload -a
                        }
                        else {
                            Write-Output "[WARN] No passphrase supplied. Attempting to rebind with site token only."
                            & $s1ctl bind "$sitetoken"
                            & $s1ctl reload -a
                        }
                    }
                    'No' {
                        Write-Output "[WARN] Trying to rebind Sentinel Agent without site passphrase."
                        & $s1ctl bind "$sitetoken"
                        & $s1ctl reload -a
                    }
                }
            }
            else {
                Write-Output "[ERROR] File Missing: $s1ctl"
            }
        }
        else {
            Write-Output "[WARN] No site token supplied. Exiting."
        }
    }
    'No' {
        Write-Output "[WARN] User quit SentinelOne rebind."
    }
}