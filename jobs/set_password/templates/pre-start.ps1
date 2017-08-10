$ErrorActionPreference = "Stop";
trap { $host.SetShouldExit(1) }

Start-Sleep 5 # Always sleep

<% if p('randomize_password.enabled') %>

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

"Setting password for user: $Username"
Set-Password -Username $Username -Password $NewPassword

<% end %>

Exit 0
