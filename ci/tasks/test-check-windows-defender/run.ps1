$ErrorActionPreference = "Stop"

Import-Module ./pester/pester.psm1;

cd .\windows-utilities-release\src\windows-utilities-tests\assets\wuts-release\jobs\check_windowsdefender\templates\modules
$pesterResults = Invoke-Pester -PassThru
if ($pesterResults.FailedCount -gt 0) {
    Exit 1
}

Exit 0
