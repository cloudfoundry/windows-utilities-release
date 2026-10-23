$ErrorActionPreference = "Stop";

function New-PrivatePolicyDirectory {
    # These scripts are rendered into the administrator-managed BOSH job bin.
    # Create with the protected DACL before writing any policy content.
    $acl = New-Object System.Security.AccessControl.DirectorySecurity
    $acl.SetSecurityDescriptorSddlForm('O:SYG:SYD:P(A;OICI;FA;;;SY)(A;OICI;FA;;;BA)')
    $path = Join-Path $PSScriptRoot ([System.IO.Path]::GetRandomFileName())
    $directory = New-Object -TypeName System.IO.DirectoryInfo -ArgumentList $path
    $directory.Create($acl)
    return $path
}


function Enable-FileSharing {
    Set-FileSharing 0
}

function Disable-FileSharing {
    Set-FileSharing 1
}

function Set-FileSharing {
    Param (
        [string]$IsDisabled=$(Throw "IsDisabled is required"),
        [string]$LGPOPath="C:\Windows\LGPO.exe"
    )

    $TxtFileContents=@"
Computer
Software\Policies\Microsoft\Windows NT\Terminal Services
fDisableCdm
DWORD:$IsDisabled
"@


    if (Test-Path $LGPOPath) {
        "Found $LGPOPath. Modifying security policies to modify support for rdp filesharing."
        $policyDirectory = New-PrivatePolicyDirectory
        try {
            $TxtFilePath = Join-Path $policyDirectory 'filesharing.txt'
            $PolFilePath = Join-Path $policyDirectory 'filesharing.pol'
            Out-File -FilePath $TxtFilePath -Encoding unicode -InputObject $TxtFileContents
            & $LGPOPath /r $TxtFilePath /w $PolFilePath /q
            if ($LASTEXITCODE -ne 0) { throw "LGPO.exe conversion failed: $LASTEXITCODE" }
            & $LGPOPath /m $PolFilePath /q
            if ($LASTEXITCODE -ne 0) { throw "LGPO.exe import failed: $LASTEXITCODE" }
        } finally {
            Remove-Item -LiteralPath $policyDirectory -Recurse -Force -ErrorAction SilentlyContinue
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
