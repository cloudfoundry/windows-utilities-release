$ErrorActionPreference = "Stop";

function Enable-FileSharing {
    Set-FileSharing 0
}

function Disable-FileSharing {
    Set-FileSharing 1
}

function Set-FileSharing {
    Param (
        [string]$IsDisabled=$(Throw "IsDisabled is required")
    )

    $TxtFileContents=@"
Computer
Software\Policies\Microsoft\Windows NT\Terminal Services
fDisableCdm
DWORD:$IsDisabled
"@

    $TxtFilePath="C:\Windows\Temp\filesharing.txt"
    $PolFilePath="C:\Windows\Temp\filesharing.pol"
    $LGPOPath="C:\Windows\LGPO.exe"

    if (Test-Path $LGPOPath) {
        "Found $LGPOPath. Modifying security policies to modify support for rdp filesharing."
        Out-File -FilePath $TxtFilePath -Encoding unicode -InputObject $TxtFileContents -Force

        & $LGPOPath /r $TxtFilePath /w $PolFilePath
        if ($LASTEXITCODE -ne 0) {
            Write-Error "LGPO.exe exited with non-zero code: ${LASTEXITCODE}"
            Exit $LASTEXITCODE
        }
        & $LGPOPath /m $PolFilePath
        if ($LASTEXITCODE -ne 0) {
            Write-Error "LGPO.exe exited with non-zero code: ${LASTEXITCODE}"
            Exit $LASTEXITCODE
        }
    } else {
        "Did not find $LGPOPath. Assuming existing security policies are sufficient to modify support for rdp filesharing."
    }
}

function Disable-RDP {
    "Preparing to disable RDP"
    $rdp = Get-Service "TermService"
    $startMode = (Get-WmiObject -Class Win32_Service -Property StartMode -Filter "Name='TermService'").StartMode
    if ($startMode -ne 'Disabled') {
        "Disabling TermService"
        $rdp | Set-Service -StartupType Disabled
    }
    $rdp.DependentServices | where { $_.Status -eq 'Running' -or $_.Status -ne 'StartPending' } | Stop-Service
    if (($rdp.Status -ne "Stopped" -or $rdp.Status -ne "StopPending")) {
        "Stopping TermService"
        $rdp | Stop-Service
    } else {
        "TermService not running, no need to stop"
    }

    Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server" -Name "fDenyTSConnections" -Value 1
    Get-NetFirewallRule -DisplayName "Remote Desktop*" | Set-NetFirewallRule -enabled false
    Disable-FileSharing
    "Successfully disabled RDP"
}
