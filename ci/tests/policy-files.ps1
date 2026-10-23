$ErrorActionPreference = 'Stop'
. "$PSScriptRoot/../../jobs/enable_rdp/templates/disable-rdp.ps1"

$script:Scratch = Join-Path ([System.IO.Path]::GetTempPath()) ([System.IO.Path]::GetRandomFileName())
[System.IO.Directory]::CreateDirectory($script:Scratch) > $null
function New-PrivatePolicyDirectory {
    $script:PolicyDirectory = Join-Path $script:Scratch ([System.IO.Path]::GetRandomFileName())
    [System.IO.Directory]::CreateDirectory($script:PolicyDirectory) > $null
    return $script:PolicyDirectory
}
$mock = Join-Path $script:Scratch 'mock-lgpo.ps1'
@'
if ($global:RejectPolicy) { $global:LASTEXITCODE = 7; return }
if (-not (Test-Path -LiteralPath $args[1])) { throw 'LGPO received a missing policy input.' }
$global:PolicyCalls.Add([string]$args[1])
if ($args[0] -eq '/r') { Copy-Item -LiteralPath $args[1] -Destination $args[3] }
$global:LASTEXITCODE = 0
'@ | Set-Content -LiteralPath $mock
try {
    $global:PolicyCalls = New-Object 'System.Collections.Generic.List[string]'
    $global:RejectPolicy = $false
    Set-FileSharing 0 -LGPOPath $mock
    if ($global:PolicyCalls.Count -ne 2) { throw 'LGPO conversion/import were not both invoked.' }
    if (Test-Path -LiteralPath $script:PolicyDirectory) { throw 'Staging directory remained after success.' }
    foreach ($path in $global:PolicyCalls) {
        if (-not $path.StartsWith($script:Scratch)) { throw 'Policy escaped the invocation directory.' }
    }
    $global:RejectPolicy = $true
    $failed = $false
    try { Set-FileSharing 1 -LGPOPath $mock } catch { $failed = $true }
    if (-not $failed) { throw 'LGPO failure was swallowed.' }
    if (Test-Path -LiteralPath $script:PolicyDirectory) { throw 'Staging directory remained after failure.' }
    Write-Output 'Policy staging/cleanup behavior passed with mocked LGPO and directory creation.'
} finally {
    Remove-Item -LiteralPath $script:Scratch -Recurse -Force
}
