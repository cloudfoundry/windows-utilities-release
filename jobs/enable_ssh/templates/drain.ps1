Start-Sleep 5

$dir = Split-Path $MyInvocation.MyCommand.Path
$imp = "$dir\disable-ssh.ps1"
if (-Not (Test-Path $imp)) {
    Write-Error "missing file: $imp"
    Exit 1
}
try {
    Import-Module $imp
    Disable-SSH > $null
} catch {
    Write-Error $_.Exception.Message
    Exit 1
}

"0"
Exit 0
