$ErrorActionPreference = 'Stop'
. "$PSScriptRoot/../../jobs/set_password/templates/account.ps1"

function Assert-True($Value, $Message) { if (-not $Value) { throw $Message } }
function net { throw 'A password update invoked an external process.' }
function New-TestAccount($Name) {
    $account = [PSCustomObject]@{Name=$Name; SchemaClassName='User'; Path="WinNT://test/$Name"; PasswordExpired=1; AccountDisabled=$true}
    $account | Add-Member ScriptMethod SetPassword {
        param($Value)
        if ($script:RejectPassword) { throw 'Password policy rejected update.' }
        $script:PasswordWasSet = $Value -eq 'test fixture password'
    }
    $account | Add-Member ScriptMethod SetInfo { $script:Committed = $true }
    return $account
}
function Get-LocalAccountDirectory { return $script:Directory }
function Get-LocalAdministratorsGroup { return $script:Group }

$script:RejectPassword = $false
$script:PasswordWasSet = $false
$script:Committed = $false
$existing = New-TestAccount 'existing'
$script:Directory = [PSCustomObject]@{Children=@($existing)}
Set-LocalAccountPassword 'existing' 'test fixture password'
Assert-True ($script:PasswordWasSet -and $script:Committed) 'Existing password was not committed.'
Assert-True ($existing.AccountDisabled) 'Custom account unexpectedly enabled.'

$script:RejectPassword = $true
$script:Committed = $false
$failed = $false
try { Set-LocalAccountPassword 'existing' 'test fixture password' } catch { $failed = $true }
Assert-True $failed 'Password policy error was swallowed.'
Assert-True (-not $script:Committed) 'Failed password update was committed.'
$script:RejectPassword = $false

$failed = $false
try { Set-LocalAccountPassword 'existing' '' } catch { $failed = $true }
Assert-True $failed 'Empty password was accepted.'

$script:Directory = [PSCustomObject]@{Children=@()}
$script:Directory | Add-Member ScriptMethod Create { param($Class,$Name) return (New-TestAccount $Name) }
$script:Group = [PSCustomObject]@{}
$script:Group | Add-Member ScriptMethod IsMember { param($Path) return $false }
$script:Group | Add-Member ScriptMethod Add { param($Path) $script:MemberAdded = $Path }
$script:MemberAdded = ''
$script:Committed = $false
Set-LocalAccountPassword 'Administrator' 'test fixture password'
Assert-True ($script:Committed -and $script:MemberAdded -eq 'WinNT://test/Administrator') 'Administrator account was not configured.'
Write-Output 'Account update behavior checks passed with mocked account directory.'
