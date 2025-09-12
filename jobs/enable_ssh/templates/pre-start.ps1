$Enabled=[bool]$<%= p("enable_ssh.enabled") %>
$FirewallRuleName = [string]"<%= p("enable_ssh.firewall_rule_name") %>"

Start-Sleep 5

if (-not $Enabled) {
    $dir = Split-Path $MyInvocation.MyCommand.Path
    $imp = "$dir\disable-ssh.ps1"
    if (-Not (Test-Path $imp)) {
        Write-Error "missing file: $imp"
        Exit 1
    }
    try {
        . $imp
        Disable-SSH
    } catch {
        Write-Error $_.Exception.Message
        Exit 1
    }
    Exit 0
}

Write "Firewall rule is: ${FirewallRuleName}"

$LGPOPath = "C:\Windows\LGPO.exe"
$InfFileContents= @'
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

if (Test-Path $LGPOPath) {
    $InfFilePath = "C:\Windows\Temp\enable-ssh.inf"
    "Found $LGPOPath. Modifying security policies to support ssh."
    Out-File -FilePath $InfFilePath -Encoding unicode -InputObject $InfFileContents -Force
    & $LGPOPath /s $InfFilePath
    if ($LASTEXITCODE -ne 0) {
        Write-Error "LGPO.exe exited with non-zero code: ${LASTEXITCODE }"
        Exit $LASTEXITCODE
    }
} else {
    "Did not find $LGPOPath. Assuming existing security policies are sufficient to support ssh."
}

# Create firewall rule if it doesn't exist
if ($FirewallRuleName -eq "SSH") {

    if ((Get-NetFirewallRule | where { $_.DisplayName -eq 'SSH' }) -eq $null) {
        Write-Output "Creating firewall rule for SSH"
        New-NetFirewallRule -Protocol TCP -LocalPort 22 -Direction Inbound -Action Allow -DisplayName SSH
    } else {
        Write-Output "Firewall rule for SSH already exists"
    }

} elseif ($FirewallRuleName -eq "OpenSSH-Server-In-TCP") {

    if (!(Get-NetFirewallRule -Name "OpenSSH-Server-In-TCP" -ErrorAction SilentlyContinue | Select-Object Name, Enabled)) {
        Write-Output "Firewall Rule 'OpenSSH-Server-In-TCP' does not exist, creating it..."
        New-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' -DisplayName 'OpenSSH Server (sshd)' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -Profile Any -LocalPort 22
    } else {
        Write-Output "Firewall rule 'OpenSSH-Server-In-TCP' already exists."
    }

} else {
    Write "Warning: unrecognized firewall rule name $FirewallRuleName; ignoring..."
}

# Do this to prevent Get-Service from error'ing
$sshd=(Get-Service | where { $_.Name -eq "sshd" })
if ($sshd -eq $null) {
    Write-Error "Error: sshd service is not installed"
    Exit 1
}
if ($sshd.Status -eq "Running") {
    "sshd service is already running, nothing to do here"
    Exit 0
}

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

"Successfully enabled ssh"
Exit 0
