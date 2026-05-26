Add-Type -AssemblyName Microsoft.VisualBasic
$ntpserver = [Microsoft.VisualBasic.Interaction]::InputBox("NTP Server:", "NTP Server", "time-a-g.nist.gov pool.ntp.org time.windows.com")

if($null -ne $ntpserver -and $ntpserver -ne ""){
    function Set-RegKeyHKLM($regkey, $name, $value, $type) {
        $regkeypart1 = $regkey | Split-Path
        If ($regkeypart1 -ne "HKLM:\"){
            $a = 1
            DO{
                $b = $a
                $a = $a + 1
                New-Variable -Name "regkeypart$($a)" -Value ($((Get-Variable -Name "regkeypart$($b)").Value) | Split-Path) -Force
            } While ($((Get-Variable -Name "regkeypart$($a)").Value) -ne "HKLM:\")
        } Else {
            $a = 0
        }
        if (Get-ItemProperty -Path "$regkey" -Name "$name" -ErrorAction Ignore) {
            if((Get-ItemPropertyValue -Path "$regkey" -Name "$name") -eq "$value") {
            } else {
                Write-Output "Modifying: $($name):$($value)"
                Set-ItemProperty -Path "$regkey" -Name "$name" -Value "$value" | Out-Null
            }
        } else {
            if ($a -ne 0) {
                DO{
                    $a = $a - 1
                    if (!(Get-Item -Path "$((Get-Variable -Name "regkeypart$($a)").Value)\" -ErrorAction Ignore)) {
                        New-Item -Path "$((Get-Variable -Name "regkeypart$($a)").Value)" | Out-Null
                    }
                } While ($a -gt 1)
            }
            if (!(Get-Item -Path "$regkey\" -ErrorAction Ignore)) {
                New-Item -Path "$regkey" | Out-Null
            }
            Write-Output "Creating: $($name):$($value)"
            New-ItemProperty -Path "$regkey" -PropertyType "$type" -Name "$name" -Value "$value" | Out-Null
        }
    }

    Set-RegKeyHKLM -regkey "HKLM:\SYSTEM\CurrentControlSet\Services\tzautoupdate" -name "Start" -value "3" -type "DWord"

    Set-RegKeyHKLM -regkey "HKLM:\SYSTEM\CurrentControlSet\Services\W32Time\Parameters" -name "Type" -value "NTP" -type "String"

    Set-RegKeyHKLM -regkey "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location" -name "Value" -value "Allow" -type "String"

    $profileList = (Get-ChildItem -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList")
    $profileList += "C:\Users\Default"
    $profileFolder = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList').ProfilesDirectory
    New-PSDrive -Name HKU -PSProvider Registry -Root HKEY_USERS | Out-Null
    $profileList | ForEach-Object {
        if ($_ -eq "C:\Users\Default"){
            $sid = "Default"
            $profilePath = "C:\Users\Default"
        }else{
            $profileKeys = Get-ItemProperty $_.PSPath	
            $sid = $profileKeys.PSChildName
            $profilePath = $profileKeys.ProfileImagePath
        }
        if ($profilePath -like "$($profileFolder)*") {	
            if (Get-ChildItem "HKU:\$sid" -ErrorAction SilentlyContinue) {
                $profileLoaded = $true
            } else {
                $profileLoaded = $false
            }
            
            Write-Output "`n${profilePath}:"
            if ($profileLoaded) {
                $userKeyPath = "HKU:\$sid"
            } else {
                $userKeyPath = "HKLM:\TempHive_$sid"
                & reg.exe load "HKLM\TempHive_$sid" "$profilePath\ntuser.dat" | Out-Null
            }

            function Set-RegKeyHKCU($regkey, $name, $value, $type) {
                $regkeypart1 = $regkey | Split-Path
                If ($regkeypart1 -ne "HKU:\" -and $regkeypart1 -ne "HKLM:\"){
                    $a = 1
                    DO{
                        $b = $a
                        $a = $a + 1
                        New-Variable -Name "regkeypart$($a)" -Value ($((Get-Variable -Name "regkeypart$($b)").Value) | Split-Path) -Force
                    } While ($((Get-Variable -Name "regkeypart$($a)").Value) -ne "HKLM:\" -and $((Get-Variable -Name "regkeypart$($a)").Value) -ne "HKU:\")
                } Else {
                    $a = 0
                }
                if (Get-ItemProperty -Path "$regkey" -Name "$name" -ErrorAction Ignore) {
                    if((Get-ItemPropertyValue -Path "$regkey" -Name "$name") -eq "$value") {
                    } else {
                        Write-Output "`nModifying: $name"
                        Set-ItemProperty -Path "$regkey" -Name "$name" -Value "$value" | Out-Null
                    }
                } else {
                    if ($a -ne 0) {
                        DO{
                            $a = $a - 1
                            if (!(Get-Item -Path "$((Get-Variable -Name "regkeypart$($a)").Value)\" -ErrorAction Ignore)) {
                                New-Item -Path "$((Get-Variable -Name "regkeypart$($a)").Value)" | Out-Null
                            }
                        } While ($a -gt 1)
                    }
                    if (!(Get-Item -Path "$regkey\" -ErrorAction Ignore)) {
                        New-Item -Path "$regkey" | Out-Null
                    }
                    Write-Output "`nCreating: $name"
                    New-ItemProperty -Path "$regkey" -PropertyType "$type" -Name "$name" -Value "$value" | Out-Null
                }
                if (Get-ItemProperty -Path "$regkey" -Name "$name" -ErrorAction Ignore) {
                    $regkeydata = (Get-ItemProperty -Path "$regkey" -Name "$name" | select-object "$name" -expandProperty "$name")
                    Write-Output "`n${Name}:$regkeydata"
                } else {
                    Write-Output "`n${Name}:NotExist"
                }
            }
            
            Set-RegKeyHKCU -regkey "$userKeyPath\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location" -name "Value" -value "Allow" -type "String"

            if (!$profileLoaded) {
                & reg.exe unload "HKLM\TempHive_$sid" 2> $null
            }
            
        }
    }

    Remove-PSDrive -Name HKU 2> $null

    Get-Service W32Time -ErrorAction SilentlyContinue | Where-Object {$_.status -ne 'Stopped'} |  Stop-Service
    cmd.exe /c w32tm /unregister
    cmd.exe /c w32tm /register
    Set-Service -Name W32Time -StartupType Automatic
    Get-Service W32Time -ErrorAction SilentlyContinue | Where-Object {$_.status -ne 'Running'} |  Start-Service
    Start-Sleep -Seconds 10
    Get-Service W32Time -ErrorAction SilentlyContinue | Where-Object {$_.status -ne 'Running'} |  Write-Output "Failed to start time service."
    Write-Output "w32TM /config /syncfromflags:manual /manualpeerlist:$ntpserver"
    cmd.exe /c w32TM /config /syncfromflags:manual /manualpeerlist:"$ntpserver"
    Get-Service w32time -ErrorAction SilentlyContinue | Where-Object {$_.status -ne 'Running'} |  Start-Service
    Write-Output "w32tm /config /update"
    cmd.exe /c w32tm /config /update
    Get-Service w32time -ErrorAction SilentlyContinue | Where-Object {$_.status -ne 'Running'} |  Start-Service
    Start-Sleep -Seconds 10
    Write-Output "w32tm /resync"
    cmd.exe /c w32tm /resync
    Get-Service w32time -ErrorAction SilentlyContinue | Where-Object {$_.status -ne 'Running'} |  Start-Service
    cmd.exe /c w32tm /query /configuration | select-string -pattern "Type:" | out-string | ForEach-Object{$_.trim()}
    Get-Service w32time -ErrorAction SilentlyContinue | Where-Object {$_.status -ne 'Running'} |  Start-Service
    cmd.exe /c w32tm /query /configuration | select-string -pattern "NtpServer:" | out-string | ForEach-Object{$_.trim()}
    Get-Service w32time -ErrorAction SilentlyContinue | Where-Object {$_.status -ne 'Running'} |  Start-Service
    Get-TimeZone | Select-Object DisplayName -ExpandProperty Displayname
    Get-Date -UFormat "%A %m/%d/%Y %r %Z"
} else {
    Write-Output "NTP server cannot be blank."
}
