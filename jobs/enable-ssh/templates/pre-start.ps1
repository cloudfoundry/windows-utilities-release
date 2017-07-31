Start-Sleep 30

$SSHDir="C:\Program Files\OpenSSH"

if (-Not (Test-Path $SSHDir)) {
    Write-Error "OpenSSH does not appear to be installed: missing directory: $SSHDir"
    Exit 1
}

if ((Get-Service sshd).Status -eq 'Running') {
    "sshd service is already running, nothing to do here"
    Exit 0
}

if ((Get-NetFirewallRule | where { $_.DisplayName -eq 'SSH' }) -eq $null) {
    "Creating firewall rule for SSH"
    New-NetFirewallRule -Protocol TCP -LocalPort 22 -Direction Inbound -Action Allow -DisplayName SSH
} else {
    "Firewall rule for SSH already exists"
}

Push-Location $SSHDir
    "Removing any existing host keys"
    Remove-Item -Path ".\ssh_host_*"

    "Generating new host keys"
    .\ssh-keygen -A

    "Fixing host key permissions"
    .\FixHostFilePermissions.ps1 -Confirm:$false
Pop-Location

"Setting 'ssh-agent' service start type to automatic"
Set-Service -Name ssh-agent -StartupType Automatic

"Setting 'sshd' service start type to automatic"
Set-Service -Name sshd -StartupType Automatic

"Starting 'ssh-agent' service"
Start-Service -Name ssh-agent

"Starting 'sshd' service"
Start-Service -Name sshd

if ((Get-Service sshd).Status -ne 'Running') {
    Write-Error "Failed to start 'sshd' service"
    Exit 1
}

"Successfully started 'ssh-agent' and 'sshd' services"
