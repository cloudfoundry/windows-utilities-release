$ErrorActionPreference = "Stop";
trap { $host.SetShouldExit(1) }

Start-Sleep 5 # Always sleep

<% if p('set_password.enabled') %>

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

[string]$Username = '<%= p("set_password.username") %>'
[string]$EncodedPass = '<%= Base64.strict_encode64(p("set_password.password")) %>'
[string]$NewPassword = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($EncodedPass))
if ($Username -eq '') {
    throw "Error: empty user name - refusing to change password"
}

"Setting password for user: $Username"
Set-Password -Username $Username -Password $NewPassword

<% end %>

Exit 0
