Start-Sleep 5

$SSHDir="C:\Program Files\OpenSSH"
$InfFilePath="C:\Windows\Temp\enable-ssh.inf"
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
SeAssignPrimaryTokenPrivilege=*S-1-5-19,*S-1-5-20,*S-1-5-80-3847866527-469524349-687026318-516638107-1125189541
'@
$LGPOPath="C:\Windows\LGPO.exe"

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

if (Test-Path $LGPOPath) {
    "Found $LGPOPath. Modifying security policies to support ssh."
    Out-File -FilePath $InfFilePath -InputObject $InfFileContents -Force
    & $LGPOPath /s $InfFilePath
} else {
    "Did not find $LGPOPath. Assuming existing security policies are sufficient to support ssh."
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
