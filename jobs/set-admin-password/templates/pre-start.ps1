Start-Sleep 30

<% if_p("set-admin-password.password") do |password| %>
  Write-Host "Changing Administrator password for windows..."
  $EncodedPass = "<%= Base64.strict_encode64(password) %>"
  $NewPassword = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($EncodedPass))
  $AdminUser = [ADSI]"WinNT://${env:computername}/Administrator,User"
  $AdminUser.SetPassword($NewPassword)

  # Optionally prevent password from expiring
  AdminUser.PasswordExpired = 0
<% end %>
