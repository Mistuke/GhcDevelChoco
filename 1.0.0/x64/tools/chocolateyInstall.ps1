#NOTE: Please remove any commented lines to tidy up prior to releasing the package, including this one

$arch = 'x64'

$thisScript = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
. ($thisScript +  '.\chocolateyInstall-Template.ps1')