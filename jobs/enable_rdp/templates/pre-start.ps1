Start-Sleep 5

$ErrorActionPreference = "Stop";
trap {
    $formatstring = "{0} : {1}`n{2}`n" +
                    "    + CategoryInfo          : {3}`n"
                    "    + FullyQualifiedErrorId : {4}`n"
    $fields = $_.InvocationInfo.MyCommand.Name,
              $_.ErrorDetails.Message,
              $_.InvocationInfo.PositionMessage,
              $_.CategoryInfo.ToString(),
              $_.FullyQualifiedErrorId

    $formatstring -f $fields
    Exit 1
}

$Enabled=[bool]$<%= p("enable_rdp.enabled") %>

#Import
$dir = Split-Path $MyInvocation.MyCommand.Path
Import-Module "$dir\disable-rdp.ps1"

# Disable RDP
if (-not $Enabled) {
    Disable-RDP
    Exit 0
}

# Enable RDP

$InfFilePath="C:\Windows\Temp\enable-rdp.inf"
$LGPOPath="C:\Windows\LGPO.exe"

$InfFileContents=@'
[Unicode]
Unicode=yes
[Version]
signature=$CHICAGO$
Revision=1
[Registry Values]
[System Access]
[Privilege Rights]
SeDenyNetworkLogonRight=*S-1-5-32-546
'@

if (Test-Path $LGPOPath) {
    "Found $LGPOPath. Modifying security policies to support rdp."
    Out-File -FilePath $InfFilePath -Encoding unicode -InputObject $InfFileContents -Force
    & $LGPOPath /s $InfFilePath
    if ($LASTEXITCODE -ne 0) {
        Write-Error "LGPO.exe exited with non-zero code: ${LASTEXITCODE}"
        Exit $LASTEXITCODE
    }
} else {
    "Did not find $LGPOPath. Assuming existing security policies are sufficient to support rdp."
}

$rdp=(Get-Service TermService)
Get-NetFirewallRule -DisplayName "Remote Desktop*" | Set-NetFirewallRule -enabled true
Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server" -Name "fDenyTSConnections" -Value 0

if ($rdp.StartType -eq 'Disabled') {
    $rdp | Set-Service -StartupType Automatic
}
if (( $rdp.Status -ne 'Running' -or $rdp.Status -ne 'StartPending' )) {
    $rdp | Start-Service
}

Enable-FileSharing

"Rdp enabled"

Exit 0
