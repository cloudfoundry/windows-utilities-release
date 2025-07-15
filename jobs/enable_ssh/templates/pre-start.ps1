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
        . $imp
        Disable-SSH
    } catch {
        Write-Error $_.Exception.Message
        Exit 1
    }
    Exit 0
}

"Starting 'sshd' service"
Start-Service -Name sshd

if ((Get-Service sshd).Status -ne 'Running') {
    Write-Error "Failed to start 'sshd' service"
    Exit 1
}

"Successfully enabled ssh"
Exit 0
