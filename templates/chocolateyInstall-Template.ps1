﻿# Chocolatey GHC Dev
#
# Licensed under the MIT License
# 
# Script based on work of Stefan Zimmermann
# 
# Copyright (C) 2015 Stefan Zimmermann <zimmermann.code@gmail.com>
# Copyright (C) 2016 Tamar Christina <tamar@zhox.com>
 
$ErrorActionPreference = 'Stop';
 
$packageName = 'ghc-devel-$arch'

#$installDir = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"
### For BinRoot, use the following instead ###
$binRoot         = Get-BinRoot
$installDir      = Join-Path $binRoot "$packageName"
$packageFullName = Join-Path $installDir ($packageName + '-' + $version)  
 
$url = 'http://repo.msys2.org/distrib/i686/msys2-base-i686-20160205.tar.xz'
$checksum = '2AA85B8995C8AB6FB080E15C8ED8B1195D7FC0F1'
$checksumType = 'SHA1'
 
$url64 = 'http://repo.msys2.org/distrib/x86_64/msys2-base-x86_64-20160205.tar.xz'
$checksum64 = 'BD689438E6389064C0B22F814764524BB974AE5B'
$checksumType64 = 'SHA1'
 
$toolsDir = Split-Path -parent $MyInvocation.MyCommand.Definition
 
$packageDir = Split-Path -parent $toolsDir
Write-Host "Adding '$packageDir' to PATH..."
Install-ChocolateyPath $packageDir

# MSYS2 zips contain a root dir named msys32 or msys64
$msysName = 'msys' + $osBitness
$msysRoot = Join-Path $binRoot $msysName
 
Write-Host "Installing to '$msysRoot'"
Install-ChocolateyZipPackage $packageName $url $binRoot $url64 `
  -checksum $checksum -checksumType $checksumType `
  -checksum64 $checksum64 -checksumType64 $checksumType64
  
# check if .tar.xz was only unzipped to tar file
# (shall work better with newer choco versions)
$tarFile = Join-Path $binRoot msys2Install
if (Test-Path $tarFile) {
    Get-ChocolateyUnzip $tarFile $binRoot
    Remove-Item $tarFile
}

Write-Host "Adding '$msysRoot' to PATH..."
# Install-ChocolateyPath $msysRoot

# Finally initialize and upgrade MSYS2 according to https://msys2.github.io
Write-Host "Initializing MSYS2..."
$msysShell = Join-Path $msysRoot ('mingw' + $osBitness + '_shell.bat')
Start-Process -Wait $msysShell -ArgumentList '-c', exit

$command = 'pacman --noconfirm --needed -Sy bash pacman pacman-mirrors msys2-runtime'
Write-Host "Updating system packages with '$command'..."
Start-Process -Wait $msysShell -ArgumentList '-c', "'$command'"

$command = 'pacman --noconfirm -Su'
Write-Host "Upgrading full system with '$command'..."
Start-Process -Wait $msysShell -ArgumentList '-c', "'$command'"

$command = 'pacman --noconfirm -S --needed git tar binutils autoconf make \
    libtool automake python python2 p7zip patch unzip \
    mingw-w64-$(uname -m)-gcc mingw-w64-$(uname -m)-python3-sphinx'
Write-Host "Installing GHC build dependencies '$command'..."
Start-Process -Wait $msysShell -ArgumentList '-c', "'$command'"

$command = 'test -d /mingw' + $osBitness + ' || mkdir /mingw' + $osBitness
Write-Host "Creating mingw folder with '$command'..."
Start-Process -Wait $msysShell -ArgumentList '-c', "'$command'"

$command = 'curl -L https://www.haskell.org/ghc/dist/7.10.3/ghc-7.10.3-i386-unknown-mingw32.tar.xz | tar -xJ -C /mingw' + $osBitness + ' --strip-components=1'
Write-Host "Installing bootstrapping GHC 7.10.3 version with '$command'..."
Start-Process -Wait $msysShell -ArgumentList '-c', "'$command'"

$command = 'mkdir -p /usr/local/bin &&
curl -LO https://www.haskell.org/cabal/release/cabal-install-1.24.0.0/cabal-install-1.24.0.0-i386-unknown-mingw32.zip &&
unzip cabal-install-1.24.0.0-rc1-x86_64-unknown-mingw32.zip -d /usr/local/bin &&
cabal update &&
cabal install -j --prefix=/usr/local alex happy'
Write-Host "Installing alex and happy with '$command'..."
Start-Process -Wait $msysShell -ArgumentList '-c', "'$command'"

$command = "echo 'export PATH=/mingw" + $osBitness + ":$PATH' >>~/.bash_profile"
Write-Host "Installing appending path with '$command'..."
Start-Process -Wait $msysShell -ArgumentList '-c', "'$command'"

Write-Host "Creating MSYS2 GHC shims..."
# Create shims to access msys