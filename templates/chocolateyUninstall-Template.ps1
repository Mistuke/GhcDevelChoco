try {

$toolsDir        = Split-Path -parent $MyInvocation.MyCommand.Definition
$packageFullName = $packageName + '-' + $version
$packageDir      = Join-Path ".." $toolsDir
  
} catch {
  throw $_.Exception
}
