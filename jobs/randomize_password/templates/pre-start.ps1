$Enabled=$<%= p("randomize_password.enabled").to_s %>
if (-not $Enabled) { Exit 0 }

. C:\var\vcap\packages\ps_modules\password.ps1

Start-Sleep 5

$ErrorActionPreference = "Stop";
trap { $host.SetShouldExit(1) }

[string]$NewPassword = Get-RandomPassword

if ($NewPassword -eq '') {
    throw "Error: password set to an empty string - refusing to change password"
}

[string]$Username = '<%= p("randomize_password.username") %>'

if ($Username -eq '') {
    throw "Error: empty user name - refusing to change password"
}

"Setting password for user: $Username"
Set-Password -Username $Username -Password $NewPassword
