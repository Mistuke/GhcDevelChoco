# Chocolatey GHC Dev
#
# Licensed under the MIT License
# 
# Copyright (C) 2016 Tamar Christina <tamar@zhox.com>
 
$ErrorActionPreference = 'Stop';
 
$packageName = 'ghc-devel-' + $arch
 
$toolsDir        = Split-Path -parent $MyInvocation.MyCommand.Definition
$packageFullName = $packageName + '-' + $version
$packageDir      = Join-Path $toolsDir ".."

if ($arch -eq 'x86') {
    $url           = 'http://repo.msys2.org/distrib/i686/msys2-base-i686-20160205.tar.xz'
    $checksum      = '2AA85B8995C8AB6FB080E15C8ED8B1195D7FC0F1'
    $checksumType  = 'SHA1'
    $osBitness     = 32
    $ghcArch       = "i386"
} else {
    $url           = 'http://repo.msys2.org/distrib/x86_64/msys2-base-x86_64-20160205.tar.xz'
    $checksum      = 'BD689438E6389064C0B22F814764524BB974AE5B'
    $checksumType  = 'SHA1'
    $osBitness     = 64
    $ghcArch       = "x86_64"
}

# MSYS2 zips contain a root dir named msys32 or msys64
$msysName = '.' #shorten the path by exporting to the same folder
$msysRoot = Join-Path $packageDir $msysName
$msysBase = Join-Path $msysRoot ("msys" + $osBitness)
 
Write-Host "Installing to '$packageDir'"
Install-ChocolateyZipPackage $packageName $url $packageDir `
  -checksum $checksum -checksumType $checksumType
  
# check if .tar.xz was only unzipped to tar file
# (shall work better with newer choco versions)
$tarFile = Join-Path $packageDir ($packageName + 'Install')
if (Test-Path $tarFile) {
    Get-ChocolateyUnzip $tarFile $msysRoot
    Remove-Item $tarFile
}

# Finally initialize and upgrade MSYS2 according to https://msys2.github.io
Write-Host "Initializing MSYS2..."
Set-Item Env:MSYSTEM ("MINGW" + $osBitness)
$msysShell     = Join-Path (Join-Path $msysName ("msys" + $osBitness)) ('msys2_shell.cmd')
$msysBashShell = Join-Path $msysBase ('usr\bin\bash')

# Create some helper functions
function execute {
    param( [string] $message
         , [string] $command
         , [bool] $ignoreExitCode = $false
         )
    
    # NOTE: For now, we have to redirect or silence stderr due to
    # https://github.com/chocolatey/choco/issues/445 
    # Instead just check the exit code
    Write-Host "$message with '$command'..."    
    $proc = Start-Process -NoNewWindow -UseNewEnvironment -Wait $msysBashShell -ArgumentList '--login', '-c', "'$command'" -RedirectStandardError nul -PassThru
    if ((-not $ignoreExitCode) -and ($proc.ExitCode -ne 0)) {
        throw ("Command '$command' did not complete successfully. ExitCode: " + $proc.ExitCode)
    }
}

function rebase {
    if ($arch -eq 'x86') {
        $command = Join-Path $msysBase "autorebase.bat"
        Write-Host "Rebasing MSYS32 after update..."
        Start-Process -WindowStyle Hidden -Wait $command
    }
}

execute "Processing MSYS2 bash for first time use" `
        "exit"

execute "Appending .profile with path information" `
        ('echo "export PATH=/mingw' + $osBitness + '/bin:\$PATH" >>~/.bash_profile')

# Now perform commands to set up MSYS2 for GHC Developments
execute "Updating system packages" `
        "pacman --noconfirm --needed -Sy bash pacman pacman-mirrors msys2-runtime"
rebase
execute "Upgrading full system" `
        "pacman --noconfirm -Su"
rebase
execute "Installing GHC Build Dependencies" `
        "pacman --noconfirm -S --needed git tar binutils autoconf make libtool automake python python2 p7zip patch unzip mingw-w64-`$(uname -m)-gcc mingw-w64-`$(uname -m)-gdb mingw-w64-`$(uname -m)-python3-sphinx"

execute "Updating SSL root certificate authorities" `
        "pacman --noconfirm -S --needed ca-certificates"

execute "Ensuring /mingw folder exists" `
        ('test -d /mingw' + $osBitness + ' || mkdir /mingw' + $osBitness)

execute "Installing bootstrapping GHC 7.10.3 version" `
        ('curl --stderr - -L https://www.haskell.org/ghc/dist/7.10.3/ghc-7.10.3-' + $ghcArch + '-unknown-mingw32.tar.xz | tar -xJ -C /mingw' + $osBitness + ' --strip-components=1')

execute "Installing alex, happy and cabal" `
        ('mkdir -p /usr/local/bin && curl --stderr - -LO https://www.haskell.org/cabal/release/cabal-install-1.24.0.0/cabal-install-1.24.0.0-i386-unknown-mingw32.zip && unzip cabal-install-1.24.0.0-i386-unknown-mingw32.zip -d /usr/local/bin && rm -f cabal-install-1.24.0.0-i386-unknown-mingw32.zip && cabal update && cabal install -j --prefix=/usr/local alex happy')

execute "Re-installing HsColour" `
        'cabal install -j --prefix=/usr/local HsColour --reinstall'

# ignore shims for MSYS2 programs directly
$files = get-childitem $installDir -include *.exe, *.bat, *.com -recurse
$i = 0;

foreach ($file in $files) {
  #generate an ignore file
  New-Item "$file.ignore" -type file -force | Out-Null
  Write-Progress -activity "Processing executables" -status "Hiding: " -percentcomplete ($i++/$files.length) -currentOperation $file
}

# Create files to access msys
Write-Host "Creating msys2 wrapper..."
$cmd = "@echo off`r`npushd %~dp0`r`n$msysShell -mingw" + $osBitness
echo "$cmd" | Out-File -Encoding ascii (Join-Path $packageDir ($packageName + ".bat"))

execute "Copying GHC gdb configuration..." `
        ('cp "' + (Join-Path $toolsDir ".gdbinit") + '" ~/.gdbinit')

Write-Host "Adding '$packageDir' to PATH..."
Install-ChocolateyPath $packageDir

Write-Output "***********************************************************************************************"
Write-Output "*"
Write-Output "*  ...And we're done!"
Write-Output "*"
Write-Output "*"
Write-Output ("*  You can run this by running '" + $packageName + ".bat' after restarting powershell")
Write-Output "*  or by launching the batch file directly."
Write-Output "*"
Write-Output "*  For instructions on how to get the sources visit https://ghc.haskell.org/trac/ghc/wiki/Building/GettingTheSources"
Write-Output "*"
Write-Output "*  For information on how to fix bugs see https://ghc.haskell.org/trac/ghc/wiki/WorkingConventions/FixingBugs"
Write-Output "*"
Write-Output "*  And for general beginners information consult https://ghc.haskell.org/trac/ghc/wiki/Newcomers"
Write-Output "*"
Write-Output "*  If you want to submit back patches, you still have some work to do."
Write-Output "*  Please follow the guide at https://ghc.haskell.org/trac/ghc/wiki/Phabricator"
Write-Output "*"
Write-Output "*  For this you do need PHP, PHP can be downloaded from http://windows.php.net/download#php-5.6"
Write-Output "*  and need to be in your PATH for arc to find it."
Write-Output "*"
Write-Output "*  For other information visit https://ghc.haskell.org/trac/ghc/wiki/Building"
Write-Output "*"
Write-Output "*"
Write-Output "*  Happy Hacking!"
Write-Output "*"
Write-Output "***********************************************************************************************"
