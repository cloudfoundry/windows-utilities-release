Import-Module ./CheckWindowsDefender.psd1

function Get-MpPreference {}

Describe "Assert-DefenderEnabled" {
    BeforeEach {
        $TrueValues = @("DisableCatchupFullScan", "DisableCatchupQuickScan", "DisableEmailScanning",
            "DisableRemovableDriveScanning", "DisableRestorePoint", "DisableScanningMappedNetworkDrivesForFullScan"
            )
        $FalseValues = @("DisableArchiveScanning", "DisableAutoExclusions", "DisableBehaviorMonitoring",
            "DisableBlockAtFirstSeen", "DisableIOAVProtection", "DisablePrivacyMode",
            "DisableRealtimeMonitoring", "DisableScanningNetworkFiles", "DisableScriptScanning"
        )
        $Global:FakeMpStatus = New-Object -TypeName 'Microsoft.Management.Infrastructure.CimInstance' -ArgumentList @('MSFT_MpPreference')
        $Global:FakeMpStatus.CimInstanceProperties.Add([Microsoft.Management.Infrastructure.CimProperty]::Create(
                "DisableIntrusionPreventionSystem", "", [Microsoft.Management.Infrastructure.CimType]::String,
                [Microsoft.Management.Infrastructure.CimFlags]::NullValue
        ))
    }

    It "returns True when expected Defender features are enabled" {
        foreach ($property in $TrueValues) {
            $Global:FakeMpStatus.CimInstanceProperties.Add([Microsoft.Management.Infrastructure.CimProperty]::Create(
                    $property, $True, [Microsoft.Management.Infrastructure.CimFlags]::None
            ))
        }
        foreach ($property in $FalseValues) {
            $Global:FakeMpStatus.CimInstanceProperties.Add([Microsoft.Management.Infrastructure.CimProperty]::Create(
                    $property, $false, [Microsoft.Management.Infrastructure.CimFlags]::None
            ))
        }

        Mock Get-MpPreference { return $Global:FakeMpStatus } -ModuleName CheckWindowsDefender

        $result = Assert-DefenderEnabled
        $result | Should Be $True
    }

    It "return false and logs disabled features when expected Defender features are disabled" {
        foreach ($property in ($TrueValues + $FalseValues)) {
            $Global:FakeMpStatus.CimInstanceProperties.Add([Microsoft.Management.Infrastructure.CimProperty]::Create(
                    $property, $True, [Microsoft.Management.Infrastructure.CimFlags]::None
            ))
        }

        Mock Get-MpPreference { return $Global:FakeMpStatus } -ModuleName CheckWindowsDefender
        Mock Write-Log { } -ModuleName CheckWindowsDefender

        $result = Assert-DefenderEnabled
        $result | Should Be $False

        foreach ($property in $FalseValues) {
            $propertyName = $property.Replace('Disable', '')
            $expectedMessage = "Expected $propertyName to be enabled, it is disabled"
            Assert-MockCalled Write-Log -Exactly 1 -Scope It -ModuleName CheckWindowsDefender -ParameterFilter { $Message -eq $expectedMessage }
        }
    }

    It "returns false and logs enabled features when Defender features are unexpectedly enabled" {
        foreach ($property in ($TrueValues + $FalseValues)) {
            $Global:FakeMpStatus.CimInstanceProperties.Add([Microsoft.Management.Infrastructure.CimProperty]::Create(
                    $property, $false, [Microsoft.Management.Infrastructure.CimType]::Boolean, [Microsoft.Management.Infrastructure.CimFlags]::None
            ))
        }

        Mock Get-MpPreference { return $Global:FakeMpStatus } -ModuleName CheckWindowsDefender
        Mock Write-Log { } -ModuleName CheckWindowsDefender

        $result = Assert-DefenderEnabled
        $result | Should Be $False

        foreach ($property in $TrueValues) {
            $propertyName = $property.Replace('Disable', '')
            $expectedMessage = "Expected $propertyName to be disabled, it is enabled"
            Assert-MockCalled Write-Log -Exactly 1 -Scope It -ModuleName CheckWindowsDefender -ParameterFilter { $Message -eq $expectedMessage }
        }
    }

    It "doesn't log that the intrusion prevention system is enabled or disabled" {
        Mock Get-MpPreference { return $Global:FakeMpStatus } -ModuleName CheckWindowsDefender
        Mock Write-Log { } -ModuleName CheckWindowsDefender

        $result = Assert-DefenderEnabled
        $result | Should Be $True

        Assert-MockCalled Write-Log -Exactly 0 -Scope It -ModuleName CheckWindowsDefender -ParameterFilter {
            $Message -eq "Expected DisableIntrusionPreventionSystem to be enabled, it is disabled"
        }
        Assert-MockCalled Write-Log -Exactly 0 -Scope It -ModuleName CheckWindowsDefender -ParameterFilter {
            $Message -eq "Expected DisableIntrusionPreventionSystem to be disabled, it is enabled"
        }
    }
}

Describe "Assert-DefenderDisabled" {
    BeforeEach {
        $AllValues = @("DisableArchiveScanning", "DisableAutoExclusions", "DisableBehaviorMonitoring",
            "DisableBlockAtFirstSeen", "DisableIOAVProtection", "DisablePrivacyMode",
            "DisableRealtimeMonitoring", "DisableScanningNetworkFiles", "DisableScriptScanning",
            "DisableCatchupFullScan", "DisableCatchupQuickScan", "DisableEmailScanning",
            "DisableRemovableDriveScanning", "DisableRestorePoint", "DisableScanningMappedNetworkDrivesForFullScan"
        )

        $Global:FakeMpStatus = New-Object -TypeName 'Microsoft.Management.Infrastructure.CimInstance' -ArgumentList @('MSFT_MpPreference')

        $Global:FakeMpStatus.CimInstanceProperties.Add([Microsoft.Management.Infrastructure.CimProperty]::Create(
                "DisableIntrusionPreventionSystem", "", [Microsoft.Management.Infrastructure.CimType]::String,
                [Microsoft.Management.Infrastructure.CimFlags]::NullValue
        ))
    }

    It "returns True when expected Windows Defender features are disabled" {
        foreach ($property in $AllValues) {
            $Global:FakeMpStatus.CimInstanceProperties.Add([Microsoft.Management.Infrastructure.CimProperty]::Create(
                    $property, $True, [Microsoft.Management.Infrastructure.CimFlags]::None
            ))
        }

        Mock Get-MpPreference { return $Global:FakeMpStatus } -ModuleName CheckWindowsDefender

        $result = Assert-DefenderDisabled
        $result | should be $True
    }

    It "returns false and logs enabled features when expected Windows Defender features are not disabled" {
        foreach ($property in $AllValues) {
            $Global:FakeMpStatus.CimInstanceProperties.Add([Microsoft.Management.Infrastructure.CimProperty]::Create(
                    $property, $False, [Microsoft.Management.Infrastructure.CimFlags]::None
            ))
        }

        Mock Get-MpPreference { return $Global:FakeMpstatus } -ModuleName CheckWindowsDefender
        Mock Write-Log {} -ModuleName CheckWindowsDefender

        $result = Assert-DefenderDisabled
        $result | should be $False

        foreach ($property in $AllValues) {
            $propertyName = $property.Replace('Disable', '')
            $expectedMessage = "Expected $propertyName to be disabled, it is enabled"
            Assert-MockCalled Write-Log -Exactly 1 -Scope It -ModuleName CheckWindowsDefender -ParameterFilter { $Message -eq $expectedMessage }
        }
    }

    It "doesn't log that the intrusion prevention system is enabled or disabled" {
        Mock Get-MpPreference { return $Global:FakeMpStatus } -ModuleName CheckWindowsDefender
        Mock Write-Log { } -ModuleName CheckWindowsDefender

        $result = Assert-DefenderDisabled
        $result | Should Be $True

        Assert-MockCalled Write-Log -Exactly 1 -Scope It -ModuleName CheckWindowsDefender -ParameterFilter {
            $Message -eq "Expected DisableIntrusionPreventionSystem to be disabled, it is enabled"
        }
    }
}

Remove-Module -Name CheckWindowsDefender