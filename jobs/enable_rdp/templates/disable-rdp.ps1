$ErrorActionPreference = "Stop";

function Disable-RDP {
    "Preparing to disable RDP"
    $rdp = Get-Service "TermService"
    if ($rdp.StartType -ne 'Disabled') {
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

    "Successfully disabled RDP"
}
