# Chocolatey GHC Dev
#
# Licensed under the MIT License
# 
# Copyright (C) 2016 Tamar Christina <tamar@zhox.com>

# Include the shared scripts
$thisScript = Split-Path -Parent $MyInvocation.MyCommand.Definition
. ($thisScript +  '.\chocolateyShared-Template.ps1')

if ($arch -eq 'x86') {
    $url           = 'http://repo.msys2.org/distrib/i686/msys2-base-i686-20160205.tar.xz'
    $checksum      = '2AA85B8995C8AB6FB080E15C8ED8B1195D7FC0F1'
    $checksumType  = 'SHA1'
} else {
    $url           = 'http://repo.msys2.org/distrib/x86_64/msys2-base-x86_64-20160205.tar.xz'
    $checksum      = 'BD689438E6389064C0B22F814764524BB974AE5B'
    $checksumType  = 'SHA1'
}

# Continue with package 
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

execute "Processing MSYS2 bash for first time use" `
        "exit"

execute "Appending profile with path information" `
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
        ('curl --stderr - -LO https://www.haskell.org/ghc/dist/7.10.3/ghc-7.10.3-' + $ghcArch + '-unknown-mingw32.tar.xz && tar -xJ -C /mingw' + $osBitness + ' --strip-components=1 -f ghc-7.10.3-' + $ghcArch + '-unknown-mingw32.tar.xz && rm -f ghc-7.10.3-' + $ghcArch + '-unknown-mingw32.tar.xz')

execute "Installing alex, happy and cabal" `
        ('mkdir -p /usr/local/bin && curl --stderr - -LO https://www.haskell.org/cabal/release/cabal-install-1.24.0.0/cabal-install-1.24.0.0-i386-unknown-mingw32.zip && unzip cabal-install-1.24.0.0-i386-unknown-mingw32.zip -d /usr/local/bin && rm -f cabal-install-1.24.0.0-i386-unknown-mingw32.zip && cabal update && cabal install -j --prefix=/usr/local alex happy')

execute "Re-installing HsColour" `
        'cabal install -j --prefix=/usr/local HsColour --reinstall'

# Create files to access msys
Write-Host "Creating msys2 wrapper..."
$cmd = "@echo off`r`npushd %~dp0`r`n$msysShell -mingw" + $osBitness
echo "$cmd" | Out-File -Encoding ascii (Join-Path $packageDir ($packageName + ".cmd"))

execute "Copying GHC gdb configuration..." `
        ('cp "' + (Join-Path $toolsDir ".gdbinit") + '" ~/.gdbinit')

# Install Arcanist   
if ($useArc -eq $true) {
    Write-Host "Setting up Arcanist as requested."

    execute "Installing php" `
            'mkdir -p /usr/local/bin && curl --stderr - -LO http://windows.php.net/downloads/releases/php-5.6.22-Win32-VC11-x86.zip && unzip php-5.6.22-Win32-VC11-x86.zip -d /usr/local/bin && rm -f php-5.6.22-Win32-VC11-x86.zip'

    execute "Cloning arcanist" `
            "git clone https://github.com/phacility/libphutil.git && git clone https://github.com/phacility/arcanist.git"

    execute "Adding arcanist to path information" `
            'echo "export PATH=$(pwd)/arcanist/bin:\$PATH" >>~/.bash_profile'
            
    execute "Copying PHP configuration..." `
            ('cp "' + (Join-Path $toolsDir "php.ini") + '" /usr/local/bin/php.ini')
}

# Get the GHC sources
if ($getSource -eq $true) {
    Write-Host "Getting a checkout of GHC for your coding pleasure..."

    execute "Fetching sources..." `
            "git clone --recursive git://git.haskell.org/ghc.git" 

    # Configure Arcanist if it was installed
    if ($useArc -eq $true) {
        execute "Initializing arc..." `
                "cd ghc && arc install-certificate"
    }
}

# Install Hadrian
if ($useHadrian -eq $true) {
    Write-Host "Setting up Hadrian as requested."

    execute "Fetching sources..." `
            "cd ghc && git clone git://github.com/snowleopard/hadrian && cd hadrian && cabal install"
}

# Install SSHd 
if ($useSsh -eq $true) {
    Write-Host "Setting up SSH as requested."

    execute "Installing SSHd dependencies" `
            "pacman --noconfirm -S --needed openssh cygrunsrv mingw-w64-x86_64-editrights"

    execute "Configuring SSHd..." `
        ('cp "' + (Join-Path $toolsDir "setup_sshd.sh") + '" ~/setup_sshd.sh && sh ~/setup_sshd.sh && rm ~/setup_sshd.sh')

    # Open firewall port
    Write-Host "Opening firewall for SSHd access"
    netsh advfirewall firewall add rule name='MSYS2 SSHd' dir=in action=allow protocol=TCP localport=$SSH_PORT
}

Write-Host "Preventing Chocolatey shims..."
# ignore shims for MSYS2 programs directly
$files = get-childitem $installDir -include *.exe, *.bat, *.com -recurse
$i = 0;

foreach ($file in $files) {
  #generate an ignore file
  New-Item "$file.ignore" -type file -force | Out-Null
  Write-Progress -activity "Processing executables" -status "Hiding: " -percentcomplete ($i++/$files.length) -currentOperation $file
}

Write-Host "Adding '$packageDir' to PATH..."
Install-ChocolateyPath $packageDir

Write-Output "***********************************************************************************************"
Write-Output "*"
Write-Output "*  ...And we're done!"
Write-Output "*"
Write-Output "*"
Write-Output ("*  You can run this by running '" + $packageName + ".cmd' after restarting powershell")
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
if ($useArc -eq $false) {
    Write-Output "*  For this you do need PHP, PHP can be downloaded from http://windows.php.net/download#php-5.6"
    Write-Output "*  and need to be in your PATH for arc to find it."
    Write-Output "*"
} elseif ($getSource -eq $false) {
    Write-Output "*  arc has been installed. Once you check out the ghc code, perform the following commands to finish the install:"
    Write-Output "*  cd ~/code/ghc-head"
    Write-Output "*  arc install-certificate"
    Write-Output "*"
}
if ($useSsh -eq $true) {
    $hostname=hostname
    Write-Output ("*  SSH has been installed and configured to run on PORT " + $SSH_PORT + ".")
    Write-Output ("*  For reference. This computer is named " + $hostname + ".")
    Write-Output "*"
}
if ($getSource -eq $true) {
    Write-Output "*  A checkout of the GHC sources has been made in ~/ghc."
    Write-Output "*"
}
if ($useHadrian -eq $true) {
    Write-Output "*  Hadrian has been installed and configured in ~/ghc."
    Write-Output "*  This means you can now use shake to build GHC."
    Write-Output "*  See https://github.com/snowleopard/hadrian for instructions."
    Write-Output "*"
}

Write-Output "*  For other information visit https://ghc.haskell.org/trac/ghc/wiki/Building"
Write-Output "*"
Write-Output "*"
Write-Output "*  Happy Hacking!"
Write-Output "*"
Write-Output "***********************************************************************************************"
Write-Output "Waiting for chocolatey to finish..."
