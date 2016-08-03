$arch = 'x86'

# save argument list for possible later consumption
$argsList = $args

$thisScript = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
. ($thisScript +  '.\chocolateyInstall-Template.ps1')