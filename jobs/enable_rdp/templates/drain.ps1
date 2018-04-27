Start-Sleep 5

$OutLog = "C:\var\vcap\sys\log\enable_rdp\drain.stdout.log"
$ErrLog = "C:\var\vcap\sys\log\enable_rdp\drain.stderr.log"

$ErrorActionPreference = "Stop";
trap {
    $formatstring = "{0} : {1}`n{2}`n" +
                    "    + CategoryInfo          : {3}`n"
                    "    + FullyQualifiedErrorId : {4}`n"
    $fields = $_.InvocationInfo.MyCommand.Name,
              $_.ErrorDetails.Message,
              $_.InvocationInfo.PositionMessage,
              $_.CategoryInfo.ToString(),
              $_.FullyQualifiedErrorId

    $formatstring -f $fields | Out-File -FilePath $ErrLog -Encoding ascii
    Exit 1
}

$dir = Split-Path $MyInvocation.MyCommand.Path
. "$dir\disable-rdp.ps1"

Disable-RDP | Out-File -FilePath $OutLog -Encoding ascii

"0"
Exit 0
