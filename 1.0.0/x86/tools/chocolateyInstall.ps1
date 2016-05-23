#NOTE: Please remove any commented lines to tidy up prior to releasing the package, including this one

$arch = 'x86'
$osBitness = 32

$thisScript = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
. ($thisScript +  '.\chocolateyInstall-Template.ps1')