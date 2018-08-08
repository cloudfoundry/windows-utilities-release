$ErrorActionPreference = "Stop";
trap { $host.SetShouldExit(1) }

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

if ($Username -eq 'Administrator')  {
    "Ensure user [$Username] is created"
    net user $Username $NewPassword /add
    "Ensure user is active"
    net user $Username /active:yes
    "Ensure user is an Admin"
    net localgroup Administrators $Username /add
}

"Setting password for user: $Username"
net user $Username $NewPassword

<% end %>

Exit 0
