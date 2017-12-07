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

function Test-User() {
    param(
        [parameter(Mandatory=$true)]
        [string]$Username
    )

    $User = Get-WMiObject -class Win32_UserAccount | Where {$_.Name -eq $Username}
    return $User -ne $null
}

[string]$Username = '<%= p("set_password.username") %>'
[string]$EncodedPass = '<%= Base64.strict_encode64(p("set_password.password")) %>'
[string]$NewPassword = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($EncodedPass))
if ($Username -eq '') {
    throw "Error: empty user name - refusing to change password"
}

if (($Username -eq 'Administrator') -and !(Test-User -Username $Username)) {
    "Adding new user: $Username"
    net user $Username $NewPassword /add
    net localgroup Administrators $Username /add
} else {
    "Setting password for user: $Username"
    Set-Password -Username $Username -Password $NewPassword
}

<% end %>

Exit 0
