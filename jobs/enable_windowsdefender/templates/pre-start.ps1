Import-Module $PSScriptRoot/../modules/WindowsDefenderManager.psd1

$Enabled= [bool]$<%= p("enable_windowsdefender.enabled") %>

Start-Sleep 5

if ($Enabled) {
    Enable-WindowsDefenderFeatures
} else {
    Disable-WindowsDefenderFeatures
}

Exit 0