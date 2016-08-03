# Chocolatey GHC Dev
#
# Licensed under the MIT License
# 
# Copyright (C) 2016 Tamar Christina <tamar@zhox.com>
#
# This package was originally designed to run on Chocolatey,
# But Chocolatey has numerous issues both technical and procedural
# that currently makes it not a viable option. So for now shim out
# the functions that we require for compatibility so that if in the
# future we decide to, we can plug it back into Chocolatey.
#
# API And skeleton based on code from the Chocolatey project
# https://github.com/chocolatey/chocolatey/blob/master/LICENSE
# LICENSE.CHOCOLATEY included in this folder

# First lets override some variables
if ($argsList.length -eq 0 -or $argsList[0].StartsWith("/")) {
    $usrPath       = Read-Host -Prompt 'Install to'
    $toolsDir      = Join-Path $usrPath "pkg"
    $start         = 0
} else {
    $toolsDir      = Join-Path $argsList[0] "pkg"
    $start         = 1
}
$packageDir        = Join-Path $toolsDir ".."
$packageParameters = ""

# Copy some tools over
if (![System.IO.Directory]::Exists($toolsDir)) {[System.IO.Directory]::CreateDirectory($toolsDir)}
Copy-Item -Recurse -Force -Path (Join-Path $thisScript "*") -Exclude *.ps1, LICENSE* -Destination $toolsDir  

# Build the commandline argument
for ($i=$start; $i -lt $argsList.length; $i++)
{
    $packageParameters=$packageParameters + ' ' + $argsList[$i]
}
# Shim functions

function Get-ChocolateyUnzip {
param(
  [string] $fileFullPath,
  [string] $destination,
  [string] $specificFolder,
  [string] $packageName
)
  $zipfileFullPath=$fileFullPath
  if ($specificfolder) {
    $fileFullPath=join-path $fileFullPath $specificFolder
  }

  Write-Debug "Running 'Get-ChocolateyUnzip' with fileFullPath:`'$fileFullPath`'', destination: `'$destination`', specificFolder: `'$specificFolder``, packageName: `'$packageName`'";

  Write-Host "Extracting $fileFullPath to $destination..."
  if (![System.IO.Directory]::Exists($destination)) {[System.IO.Directory]::CreateDirectory($destination)}
  
  # 7zip will be in the same folder as this script.
  $7zip = Join-Path "$thisScript" (Join-Path "tools" "7za.exe")
  
  Write-Host "Using `'$7zip`'..."

  $exitCode = -1
  $unzipOps = {
    param($7zip, $destination, $fileFullPath, [ref]$exitCodeRef)
    $process = Start-Process $7zip -ArgumentList "x -o`"$destination`" -y `"$fileFullPath`"" -Wait -WindowStyle Hidden -PassThru
    # this is here for specific cases in Posh v3 where -Wait is not honored
    try { if (!($process.HasExited)) { Wait-Process -Id $process.Id } } catch { }

    $exitCodeRef.Value = $process.ExitCode
  }
  
  Invoke-Command $unzipOps -ArgumentList $7zip,$destination,$fileFullPath,([ref]$exitCode)

  Write-Debug "7za exit code: $exitCode"
  switch ($exitCode) {
    0 { break }
    1 { throw 'Some files could not be extracted' } # this one is returned e.g. for access denied errors
    2 { throw '7-Zip encountered a fatal error while extracting the files' }
    7 { throw '7-Zip command line error' }
    8 { throw '7-Zip out of memory' }
    255 { throw 'Extraction cancelled by the user' }
    default { throw "7-Zip signalled an unknown error (code $exitCode)" }
  }

  return $destination
}

function Install-ChocolateyZipPackage {
param(
  [string] $packageName,
  [string] $url,
  [string] $unzipLocation,
  [string] $url64bit = $url,
  [string] $specificFolder ="",
  [string] $checksum = '',
  [string] $checksumType = '',
  [string] $checksum64 = '',
  [string] $checksumType64 = ''
)
  Write-Debug "Running 'Install-ChocolateyZipPackage' for $packageName with url:`'$url`', unzipLocation: `'$unzipLocation`', url64bit: `'$url64bit`', specificFolder: `'$specificFolder`', checksum: `'$checksum`', checksumType: `'$checksumType`', checksum64: `'$checksum64`', checksumType64: `'$checksumType64`' ";

  Write-Host "Downloading from `'$url`'..."
  
  try {
    $fileType = 'zip'

    $tempDir = Join-Path $env:TEMP "$packageName"
    if (![System.IO.Directory]::Exists($tempDir)) {[System.IO.Directory]::CreateDirectory($tempDir) | Out-Null}
    $file = Join-Path $tempDir "$($packageName)Install.$fileType"

    # Use the .NET WebClient and just download it all.
    $webclient = New-Object System.Net.WebClient
    $webclient.DownloadFile($url,$file)
    
    Write-Host "Download finished"

    Get-ChocolateyUnzip $file $unzipLocation $specificFolder $packageName
    
    Remove-Item -Force $file

  } catch {
    Write-Error $($_.Exception.Message)
    Remove-Item -Force $file
    throw
  }
}

function Install-ChocolateyPath {
param(
  [string] $pathToInstall,
  [System.EnvironmentVariableTarget] $pathType = [System.EnvironmentVariableTarget]::User
)
  Write-Debug "Running 'Install-ChocolateyPath' with pathToInstall:`'$pathToInstall`'";
  $originalPathToInstall = $pathToInstall

  #get the PATH variable
  $envPath = $env:PATH
  if (!$envPath.ToLower().Contains($pathToInstall.ToLower()))
  {
    Write-Host "PATH environment variable does not have $pathToInstall in it. However,"
    Write-Error "I can't modify it automatically for you because my creator hasn't written"
    Write-Error "The code to do so :( ."
    Write-Error "Add `'$pathToInstall`' to your path manually if you wish."

    #add it to the local path as well so users will be off and running
    $envPSPath = $env:PATH
    $env:Path = $envPSPath + $statementTerminator + $pathToInstall
  }
}
