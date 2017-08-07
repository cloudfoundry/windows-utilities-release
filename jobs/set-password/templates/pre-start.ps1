$Enabled=$<%= p("set-password.enabled").to_s %>
if (-not $Enabled) { Exit 0 }

. C:\var\vcap\packages\ps_modules\password.ps1
Start-Sleep 5

$ErrorActionPreference = "Stop";
trap { $host.SetShouldExit(1) }

<%
    if p("set-password.password").to_s.empty?
        throw "password must be specified"
    end
%>

[string]$EncodedPass = '<%= Base64.strict_encode64(p("set-password.password")) %>'
[string]$NewPassword = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($EncodedPass))

if ($NewPassword -eq '') {
    throw "Error: password set to an empty string - refusing to change password"
}

[string]$Username = '<%= p("set-password.username") %>'

if ($Username -eq '') {
    throw "Error: empty user name - refusing to change password"
}

"Setting password for user: $Username"
Set-Password -Username $Username -Password $NewPassword
