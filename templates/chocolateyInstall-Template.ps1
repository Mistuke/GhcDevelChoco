# Chocolatey GHC Dev
#
# Licensed under the MIT License
# 
# Copyright (C) 2016 Tamar Christina <tamar@zhox.com>
 
$ErrorActionPreference = 'Stop';
 
$packageName = 'ghc-devel-' + $arch
$osBitness   = Get-ProcessorBits

#$installDir = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"
### For BinRoot, use the following instead ###
 
$toolsDir        = Split-Path -parent $MyInvocation.MyCommand.Definition
$packageFullName = $packageName + '-' + $version
$packageDir      = Join-Path $toolsDir $packageFullName

if ($arch -eq 'x86') {
    $url           = 'http://repo.msys2.org/distrib/i686/msys2-base-i686-20160205.tar.xz'
    $checksum      = '2AA85B8995C8AB6FB080E15C8ED8B1195D7FC0F1'
    $checksumType  = 'SHA1'
    $osBitness     = 32
} else {
    $url           = 'http://repo.msys2.org/distrib/x86_64/msys2-base-x86_64-20160205.tar.xz'
    $checksum      = 'BD689438E6389064C0B22F814764524BB974AE5B'
    $checksumType  = 'SHA1'
    $osBitness     = 64
}

# MSYS2 zips contain a root dir named msys32 or msys64
$msysName = 'msys2'
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

Write-Host "Adding '$msysRoot' to PATH..."
# Install-ChocolateyPath $msysRoot

# Finally initialize and upgrade MSYS2 according to https://msys2.github.io
Write-Host "Initializing MSYS2..."
$Env:MSYSTEM=$("MINGW" + $osBitness)
$msysShell     = Join-Path $msysBase ('mingw' + $osBitness + '_shell.bat')
$msysBashShell = Join-Path $msysBase ('usr\bin\bash')

# Make a backup
Copy-Item $msysShell ($msysShell + ".bak")

# Create some helper functions
function execute {
    param( [string] $message
         , [string] $command)
    
    Write-Host "$message with '$command'..."
    iex ("& " + $msysBashShell + " --login -c '$command'")
}

function rebase {
    if ($arch -eq 'x86') {
        $command = Join-Path $msysBase "autorebase.bat"
        Write-Host "Rebasing MSYS32 after update..."
        Start-Process -NoNewWindow -Wait $command
    }
}

Write-Host "Executing MSYS2 bash '$msysShell'..."
Start-Process -Wait -NoNewWindow $msysShell -ArgumentList '-c', exit

# Now perform commands to set up MSYS2 for GHC Developments
execute "Updating system packages" `
        "pacman --noconfirm --needed -Sy bash pacman pacman-mirrors msys2-runtime"
rebase
execute "Upgrading full system" `
        "pacman --noconfirm -Su"
rebase
execute "Installing GHC Build Dependencies" `
        "pacman --noconfirm -S --needed git tar binutils autoconf make libtool automake python python2 p7zip patch unzip mingw-w64-$(uname -m)-gcc mingw-w64-$(uname -m)-python3-sphinx"

execute "Updating SSL root certificate authorities" `
        "pacman --noconfirm -S --needed ca-certificates"

execute "Ensuring /mingw folder exists" `
        ('test -d /mingw' + $osBitness + ' || mkdir /mingw' + $osBitness)

execute "Installing bootstrapping GHC 7.10.3 version" `
        ('curl -L https://www.haskell.org/ghc/dist/7.10.3/ghc-7.10.3-i386-unknown-mingw32.tar.xz | tar -xJ -C /mingw' + $osBitness + ' --strip-components=1')

execute "Installing alex, happy and cabal" `
        ('mkdir -p /usr/local/bin && curl -LO https://www.haskell.org/cabal/release/cabal-install-1.24.0.0/cabal-install-1.24.0.0-i386-unknown-mingw32.zip &&unzip cabal-install-1.24.0.0-rc1-x86_64-unknown-mingw32.zip -d /usr/local/bin && cabal update && cabal install -j --prefix=/usr/local alex happy')

execute "Appending .profile with path information" `
        ("echo 'export PATH=/mingw" + $osBitness + ":$PATH' >>~/.bash_profile")

# ignore shims for MSYS2 programs directly
$files = get-childitem $installDir -include *.exe, *.bat, *.com -recurse
$i = 0;

foreach ($file in $files) {
  #generate an ignore file
  New-Item "$file.ignore" -type file -force | Out-Null
  Write-Progress -activity Updating -status 'Progress->' -percentcomplete ($i++/$files.length) -currentOperation $file
}

# Create files to access msys
Move-Item ($msysShell + ".bak") (Join-Path $packageDir (packageName + ".bat"))

Write-Host "Adding '$packageDir' to PATH..."
#Install-ChocolateyPath $packageDir