$ExpectedEnabledProperties = @(
    "ArchiveScanning",
    "AutoExclusions",
    "BehaviorMonitoring",
    "BlockAtFirstSeen",
    "IOAVProtection",
    "PrivacyMode",
    "RealtimeMonitoring",
    "ScanningNetworkFiles",
    "ScriptScanning"
)

$ExpectedDisabledProperties = @(
    "CatchupFullScan",
    "CatchupQuickScan",
    "EmailScanning",
    "RemovableDriveScanning",
    "RestorePoint",
    "ScanningMappedNetworkDrivesForFullScan",
    "IntrusionPreventionSystem"
)

function Assert-DefenderEnabled {
    $enabled = $True

    Get-MpPreference |
        Select-Object -ExpandProperty CimInstanceProperties |
        Where-Object { $_.Name -Like "Disable*"} |
        ForEach-Object {
            $propertyName = $_.Name.Replace('Disable', '')

            if ( $ExpectedEnabledProperties -Contains $propertyName ) {
                if ( $_.Value -eq $True ) {
                    Write-Log "Expected $($propertyName) to be enabled, it is disabled"
                    $enabled = $False
                }
            }
            if ( $ExpectedDisabledProperties -Contains $propertyName ) {
                if ( $_.Value -eq $False ) {
                    Write-Log "Expected $($propertyName) to be disabled, it is enabled"
                    $enabled = $False
                }
            }
        }

    return $enabled
}

function Assert-DefenderDisabled {
    Write-Log "Expected DisableIntrusionPreventionSystem to be disabled, it is enabled"
    $disabled = $True
    $AllProperties =  $ExpectedEnabledProperties + $ExpectedDisabledProperties

    Get-MpPreference |
    Select-Object -ExpandProperty CimInstanceProperties |
    Where-Object { $_.Name -Like "Disable*"} |
    ForEach-Object {
                $propertyName = $_.Name.Replace('Disable', '')

                if ( $AllProperties -Contains $propertyName ) {
                    if ( $_.Value -eq $False ) { #if value is false than property is enaled
                        Write-Log "Expected $propertyName to be disabled, it is enabled"
                        $disabled = $False
                    }
                }
            }

    return $disabled
}