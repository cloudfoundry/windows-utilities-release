$FeaturesToEnable = @(
    "DisableArchiveScanning",
    "DisableAutoExclusions",
    "DisableBehaviorMonitoring",
    "DisableBlockAtFirstSeen",
    "DisableIOAVProtection",
    "DisablePrivacyMode",
    "DisableRealtimeMonitoring",
    "DisableScanningNetworkFiles",
    "DisableScriptScanning"
)

$FeaturesToDisable = $FeaturesToEnable + @(
    "DisableCatchupFullScan",
    "DisableCatchupQuickScan",
    "DisableEmailScanning",
    "DisableRemovableDriveScanning",
    "DisableRestorePoint",
    "DisableScanningMappedNetworkDrivesForFullScan"
)

function Enable-WindowsDefenderFeatures {
    if (Get-Command -Name Set-MpPreference) {
        foreach ($feature in $FeaturesToEnable) {
            iex "Set-MpPreference -$feature `$False"
        }
    } else {
        throw "Windows Defender is not installed on the current stemcell, the enable_windowsdefender job can only be deployed using stemcells with Defender installed"
    }
}

function Disable-WindowsDefenderFeatures {
    foreach ($feature in $FeaturesToDisable) {
        iex "Set-MpPreference -$feature `$True"
    }
}
