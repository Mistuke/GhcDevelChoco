try {

$toolsDir        = Split-Path -parent $MyInvocation.MyCommand.Definition
$packageFullName = $packageName + '-' + $version
$packageDir      = Join-Path ".." $toolsDir
  
# MSYS2 zips contain a root dir named msys32 or msys64
$msysName = '.' #shorten the path by exporting to the same folder
$msysRoot = Join-Path $packageDir $msysName
$msysBase = Join-Path $msysRoot ("msys" + $osBitness)

# Whatever chocolatey is doing during an uninstall is taking too long
# It's making this uninstall take hours which is unacceptably slow
# when all we want is to remove the files. So I'm removing the msys2
# folder manually.
rm -r -fo $msysBase

} catch {
  throw $_.Exception
}
