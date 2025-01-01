$ErrorActionPreference = "Stop"

Import-Module ./pester/pester.psm1;

cd .\windows-utilities-release\jobs\enable_windowsdefender\templates\modules
$pesterResults = Invoke-Pester -PassThru
if ($pesterResults.FailedCount -gt 0) {
    Exit 1
}

Exit 0
