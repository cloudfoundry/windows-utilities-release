@{
    RootModule = 'WindowsDefenderManager'
    ModuleVersion = '0.1'
    GUID = 'a1ce1b0c-7a12-4ed4-a452-e9c8191836b6'
    Author = 'BOSH'
    Copyright = '(c) 2019 BOSH'
    Description = 'Provide functionality to enable and disable Windows Defender features'
    PowerShellVersion = '4.0'
    RequiredModules = @()
    FunctionsToExport = @('Enable-WindowsDefenderFeatures', 'Disable-WindowsDefenderFeatures')
    CmdletsToExport = @()
    VariablesToExport = @()
    AliasesToExport = @()
    PrivateData = @{
        PSData = @{
            Tags = @('CloudFoundry')
            LicenseUri = 'https://github.com/cloudfoundry-incubator/windows-utilities-release/blob/master/LICENSE'
            ProjectUri = 'https://github.com/cloudfoundry-incubator/windows-utilities-release'
        }
    }
}
