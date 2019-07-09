Import-Module $PSScriptRoot/../modules/WindowsDefenderManager.psd1

Start-Sleep 5

Disable-WindowsDefenderFeatures

"0"
Exit 0
