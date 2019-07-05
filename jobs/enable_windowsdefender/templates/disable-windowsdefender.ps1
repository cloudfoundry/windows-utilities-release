function Disable-WindowsDefender{
    #Check to see that windows defender is installed
    $defenderProperties = Get-WindowsFeature -Name "Windows-Defender"
    if ($defenderProperties.InstallState -ne "Installed" ) {
        Write-Error "Cannot disable Windows Defender; Windows Defender is not installed"
        Exit 1
    }

    #Disable Windows Defender
    Set-MpPreference -DisableRealtimeMonitoring $true

    #Check that the system says its disabled
    $mpPreferences = Get-MpPreference
    $isDefenderDisabled = $mpPreferences.DisableRealTimeMonitoring
    if($isDefenderDisabled -eq $false) {
        Write-Error "Failed to disable Windows Defender"
        Exit 1
    }
}

