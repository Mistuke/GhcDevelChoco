$arch = 'x64'

# save argument list for possible later consumption
$argsList = $args

$thisScript = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
. ($thisScript +  '.\chocolateyUninstall-Template.ps1')