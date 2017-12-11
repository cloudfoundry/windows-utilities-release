$ErrorActionPreference = "Stop";
trap { $host.SetShouldExit(1) }

Start-Sleep 5 # Always sleep

<% if p('set_password.enabled') %>

[string]$Username = '<%= p("set_password.username") %>'
[string]$EncodedPass = '<%= Base64.strict_encode64(p("set_password.password")) %>'
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
