Import-Module $PSScriptRoot/WindowsDefenderManager.psd1

function Set-MpPreference() {
    param(
        [bool]$DisableArchiveScanning,
        [bool]$DisableAutoExclusions,
        [bool]$DisableBehaviorMonitoring,
        [bool]$DisableBlockAtFirstSeen,
        [bool]$DisableIOAVProtection,
        [bool]$DisablePrivacyMode,
        [bool]$DisableRealtimeMonitoring,
        [bool]$DisableScanningNetworkFiles,
        [bool]$DisableScriptScanning,
        [bool]$DisableCatchupFullScan,
        [bool]$DisableCatchupQuickScan,
        [bool]$DisableEmailScanning,
        [bool]$DisableRemovableDriveScanning,
        [bool]$DisableRestorePoint,
        [bool]$DisableScanningMappedNetworkDrivesForFullScan
    )
}

Describe "Enable-WindowsDefenderFeatures" {
    It "sets the expected windows defender disable options to false" {
        $expectedFalseSettings = @("DisableArchiveScanning", "DisableAutoExclusions", "DisableBehaviorMonitoring",
            "DisableBlockAtFirstSeen", "DisableIOAVProtection", "DisablePrivacyMode", "DisableRealtimeMonitoring",
            "DisableScanningNetworkFiles", "DisableScriptScanning"
        )

        Mock Set-MpPreference {} -ModuleName WindowsDefenderManager

        { Enable-WindowsDefenderFeatures } | Should Not Throw

        foreach ($property in $expectedFalseSettings) {
            Assert-MockCalled Set-MpPreference -Exactly 1 -Scope it -ModuleName WindowsDefenderManager -ParameterFilter {
                iex "`$$property -eq `$False"
            }
        }
    }

    It "doesn't set any unexpected windows defender disable options to anything" {
        $expectedUnmodifiedSettings = @("DisableCatchupFullScan", "DisableCatchupQuickScan", "DisableEmailScanning",
            "DisableRemovableDriveScanning", "DisableRestorePoint", "DisableScanningMappedNetworkDrivesForFullScan"
        )

        Mock Set-MpPreference {} -ModuleName WindowsDefenderManager

        { Enable-WindowsDefenderFeatures } | Should Not Throw

        foreach ($property in $expectedUnmodifiedSettings) {
            Assert-MockCalled Set-MpPreference -Exactly 0 -Scope it -ModuleName WindowsDefenderManager -ParameterFilter {
                iex "`$$property -eq `$False"
            }
        }
    }
}

Describe "Disable-WindowsDefenderFeatures" {
    It "sets the expected Windows Defender disable options to false" {
        $defenderSettings = @("DisableArchiveScanning", "DisableAutoExclusions", "DisableBehaviorMonitoring",
            "DisableBlockAtFirstSeen", "DisableIOAVProtection", "DisablePrivacyMode",
            "DisableRealtimeMonitoring", "DisableScanningNetworkFiles", "DisableScriptScanning",
            "DisableCatchupFullScan", "DisableCatchupQuickScan", "DisableEmailScanning",
            "DisableRemovableDriveScanning", "DisableRestorePoint", "DisableScanningMappedNetworkDrivesForFullScan"
        )

        Mock Set-MpPreference {} -ModuleName WindowsDefenderManager

        { Disable-WindowsDefenderFeatures } | Should Not Throw

        foreach ($property in $defenderSettings) {
            Assert-MockCalled Set-MpPreference -Exactly 1 -Scope It -ModuleName WindowsDefenderManager -ParameterFilter {
                iex "`$$property -eq `$True"
            }
        }
    }
}

Remove-Module -Name WindowsDefenderManager