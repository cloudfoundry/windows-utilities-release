Start-Sleep 5

$ErrorActionPreference = "Stop";
trap { $host.SetShouldExit(1) }

$CharList = "!`"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_``abcdefghijklmnopqrstuvwxyz{|}~".ToCharArray()

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

<%
    if !p("set-admin-password.randomize-password") && p("set-admin-password.password").nil?
        throw "either password or randomize-password must be specified"
    end
    if p("set-admin-password.randomize-password") && !p("set-admin-password.password").empty?
        throw "both password and randomize-password are specified - only one may be specified"
    end
%>

[string]$NewPassword = ''

<% if_p("set-admin-password.password") do |password| %>
    "Found: set-admin-password.password"
    [string]$EncodedPass = "<%= Base64.strict_encode64(password) %>"
    [string]$NewPassword = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($EncodedPass))
<% end %>

<% if p("set-admin-password.randomize-password") %>
    [string]$NewPassword = Get-RandomPassword
    "Found: set-admin-password.randomize-password"
<% end %>

if ($NewPassword -eq '') {
    throw "Error: password set to an empty string - refusing to change password"
}

[string]$Username = '<%= p("set-admin-password.username") %>'

if ($Username -eq '') {
    throw "Error: empty user name - refusing to change password"
}

"Setting password for user: $Username"
Set-Password -Username $Username -Password $NewPassword
