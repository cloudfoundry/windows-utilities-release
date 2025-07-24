$FirewallRuleName = [string]"<%= p("enable_ssh.firewall_rule_name") %>"

function Disable-SSH {
    # Do this to prevent Get-Service from error'ing
    $sshd=(Get-Service | where { $_.Name -eq 'sshd' })
    if ($sshd -eq $null) {
        Write-Error "Error: sshd service is not installed"
    }
    if (($sshd.Status -eq "Running") -or ($sshd.Status -eq "StartPending")) {
        "stopping service: sshd"
        $sshd | Stop-Service
    }
    if ($sshd.StartupType -ne 'Disabled') {
        "disabling service: sshd"
        $sshd | Set-Service -StartupType Disabled
    }

    $agent=(Get-Service | where { $_.Name -eq 'ssh-agent' })
    if ($agent -eq $null) {
        Write-Error "Error: ssh-agent service is not installed"
    }
    if (($agent.Status -eq "Running") -or ($agent.Status -eq "StartPending")) {
        "stopping service: ssh-agent"
        $agent | Stop-Service
    }
    if ($agent.StartupType -ne 'Disabled') {
        "disabling service: ssh-agent"
        $agent | Set-Service -StartupType Disabled
    }

    # repair firewall

    $rule = (Get-NetFirewallRule | where { $_.DisplayName -eq $FirewallRuleName })
    if ($rule -ne $null) {
        "Removing firewall rule: SSH"
        $rule | Remove-NetFirewallRule
    }
}
