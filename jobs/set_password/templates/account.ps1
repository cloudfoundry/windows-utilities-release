function Get-LocalAccountDirectory {
    return [ADSI]"WinNT://${env:COMPUTERNAME},computer"
}

function Get-LocalAdministratorsGroup {
    $sid = New-Object -TypeName System.Security.Principal.SecurityIdentifier -ArgumentList 'S-1-5-32-544'
    $name = $sid.Translate([System.Security.Principal.NTAccount]).Value.Split('\')[-1]
    return [ADSI]"WinNT://${env:COMPUTERNAME}/${name},group"
}

function Set-LocalAccountPassword {
    param(
        [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string]$Username,
        [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string]$Password
    )

    $directory = Get-LocalAccountDirectory
    $account = $directory.Children | Where-Object {
        $_.SchemaClassName -eq 'User' -and $_.Name -eq $Username
    } | Select-Object -First 1

    if ($null -eq $account) {
        if ($Username -ne 'Administrator') {
            throw 'The requested local account does not exist.'
        }
        $account = $directory.Create('user', $Username)
    }

    # ADSI executes in-process: passwords never become child-process arguments.
    # COM failures terminate the job before it can report a successful rotation.
    $account.SetPassword($Password)
    $account.PasswordExpired = 0
    if ($Username -eq 'Administrator') {
        $account.AccountDisabled = $false
    }
    $account.SetInfo()

    if ($Username -eq 'Administrator') {
        $group = Get-LocalAdministratorsGroup
        if (-not $group.IsMember($account.Path)) {
            $group.Add($account.Path)
        }
    }
}
