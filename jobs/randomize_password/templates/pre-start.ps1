$ErrorActionPreference = "Stop";
trap { $host.SetShouldExit(1) }

Start-Sleep 5 # Always sleep

<% if p('randomize_password.enabled') %>

function Is-Special() {
    param([parameter(Mandatory=$true)] [string]$c)

    return ('!' -le $c -and $c -le '/') -or (':' -le $c -and $c -le '@') -or `
        ('[' -le $c -and $c -le '`') -or ('{' -le $c -and $c -le '~')
}

function Valid-Password() {
    param([parameter(Mandatory=$true)] [string]$Password)

    $digits = 0
    $special = 0
    $alphaLow = 0
    $alphaHigh = 0

    if ($Password.Length -lt 8) {
        return $false
    }
    foreach ($c in $Password.ToCharArray()) {
        if ('0' -le $c -and $c -le '9') {
            $digits = 1
        } elseif ('a' -le $c -and $c -le 'z') {
            $alphaLow = 1
        } elseif ('A' -le $c -and $c -le 'Z') {
            $alphaHigh = 1
        } elseif (Is-Special $c) {
            $special = 1
        } else {
            # Invalid char
            return $false
        }
    }
    return ($digits + $special + $alphaLow + $alphaHigh) -ge 3
}

function Get-RandomPassword() {
    $CharList = "!`"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_``abcdefghijklmnopqrstuvwxyz{|}~".ToCharArray()
    $limit = 200
    $count = 0

    while ($limit-- -gt 0) {
        $passwd = (Get-Random -InputObject $CharList -Count 24) -join ''
        if (Valid-Password -Password $passwd) {
            return $passwd
        }
    }
    throw "Unable to generate a valid password after 200 attempts"
    return $null
}

function Set-Password() {
    param(
        [parameter(Mandatory=$true)]
        [string]$Username,
        [parameter(Mandatory=$true)]
        [string]$Password
    )
    $AdsiUser = [ADSI]"WinNT://${env:computername}/${Username},User"
    $AdsiUser.SetPassword($Password)
    $AdsiUser.PasswordExpired = 0
    $AdsiUser.setinfo()
}

[string]$Username = '<%= p("randomize_password.username") %>'
if ($Username -eq '') {
    throw "Error: empty user name - refusing to change password"
}

[string]$NewPassword = Get-RandomPassword
if ($NewPassword -eq '') {
    throw "Error: generating random password"
}

"Setting password for user: $Username"
Set-Password -Username $Username -Password $NewPassword

<% end %>

Exit 0
