$ErrorActionPreference = "Stop";
trap { [Console]::Error.WriteLine("Local account update failed: $($_.Exception.Message)"); Exit 1 }

<% require "base64" %>

Start-Sleep 5 # Always sleep

<% if p('set_password.enabled') %>

<% user = p("set_password.username")
   user = ':' + user.to_s if (user.class == Symbol)
   pass = p("set_password.password")
   pass = ':' + pass.to_s if (pass.class == Symbol)
%>
[string]$Username = '<%= user %>'
[string]$EncodedPass = '<%= Base64.strict_encode64(pass) %>'
[string]$NewPassword = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($EncodedPass))
if ($Username -eq '') {
    throw "Error: empty user name - refusing to change password"
}

if ($NewPassword -eq '') {
    throw "Error: empty password - refusing to change password"
}

. "$PSScriptRoot\account.ps1"
Set-LocalAccountPassword -Username $Username -Password $NewPassword

<% end %>

Exit 0
