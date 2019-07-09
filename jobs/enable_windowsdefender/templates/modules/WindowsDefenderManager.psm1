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
    foreach ($feature in $FeaturesToEnable) {
        iex "Set-MpPreference -$feature `$False"
    }
}

function Disable-WindowsDefenderFeatures {
    foreach ($feature in $FeaturesToDisable) {
        iex "Set-MpPreference -$feature `$True"
    }
}
