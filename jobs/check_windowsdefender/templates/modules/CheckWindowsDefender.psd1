@{
    RootModule = 'CheckWindowsDefender.psm1'
    ModuleVersion = '0.1'
    GUID = 'a58f5dc1-cf46-403e-949e-c7739256bc9f'
    Author = 'BOSH'
    Copyright = '(c) 2019 BOSH'
    Description = 'Provide functionality for checking the state of various Windows Defender features'
    PowerShellVersion = '4.0'
    RequiredModules = @()
    FunctionsToExport = @('Assert-DefenderEnabled', 'Assert-DefenderDisabled')
    CmdletsToExport = @()
    VariablesToExport = @()
    AliasesToExport = @()
    PrivateData = @{
        PSData = @{
            Tags = @('CloudFoundry')
            LicenseUri = 'https://github.com/cloudfoundry-incubator/windows-utilities-tests/blob/master/LICENSE'
            ProjectUri = 'https://github.com/cloudfoundry-incubator/windows-utilities-tests'
        }
    }
}
