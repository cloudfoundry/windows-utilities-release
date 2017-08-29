$Enabled=[bool]$<%= p("enable_ssh.enabled") %>

Start-Sleep 5

if (-not $Enabled) {
    $dir = Split-Path $MyInvocation.MyCommand.Path
    $imp = "$dir\disable-ssh.ps1"
    if (-Not (Test-Path $imp)) {
        Write-Error "missing file: $imp"
        Exit 1
    }
    try {
        Import-Module $imp
        Disable-SSH
    } catch {
        Write-Error $_.Exception.Message
        Exit 1
    }
    Exit 0
}

$EnableSSHPath="C:\var\vcap\packages\enable_ssh\enable_ssh.exe"
$SSHDir="C:\Program Files\OpenSSH"
$InfFilePath="C:\Windows\Temp\enable-ssh.inf"
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
SeAssignPrimaryTokenPrivilege=*S-1-5-19,*S-1-5-20,*S-1-5-80-3847866527-469524349-687026318-516638107-1125189541
'@

if (-Not (Test-Path $SSHDir)) {
    Write-Error "OpenSSH does not appear to be installed: missing directory: $SSHDir"
    Exit 1
}

if (-Not (Test-Path $EnableSSHPath)) {
    Write-Error "Missing enable_ssh.exe: missing executable: $EnableSSHPath"
    Exit 1
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

if ((Get-NetFirewallRule | where { $_.DisplayName -eq 'SSH' }) -eq $null) {
    "Creating firewall rule for SSH"
    New-NetFirewallRule -Protocol TCP -LocalPort 22 -Direction Inbound -Action Allow -DisplayName SSH
} else {
    "Firewall rule for SSH already exists"
}

if (Test-Path $LGPOPath) {
    "Found $LGPOPath. Modifying security policies to support ssh."
    Out-File -FilePath $InfFilePath -Encoding unicode -InputObject $InfFileContents -Force
    & $LGPOPath /s $InfFilePath
    if ($LASTEXITCODE -ne 0) {
        Write-Error "LGPO.exe exited with non-zero code: ${LASTEXITCODE}"
        Exit $LASTEXITCODE
    }
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

"Enabling key based authentication"
C:\var\vcap\packages\enable_ssh\enable_ssh.exe
if ($LASTEXITCODE -ne 0) {
    Write-Error "enable_ssh.exe exited with non-zero code: ${LASTEXITCODE}"
    Exit $LASTEXITCODE
}

"Successfully enabled ssh"
Exit 0
