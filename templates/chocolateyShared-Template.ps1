# Chocolatey GHC Dev
#
# Licensed under the MIT License
# 
# Copyright (C) 2016 Tamar Christina <tamar@zhox.com>
 
$ErrorActionPreference = 'Stop';
 
$packageName = 'ghc-devel-' + $arch
 
$toolsDir        = Split-Path -Parent $MyInvocation.MyCommand.Definition
$packageDir      = Join-Path $toolsDir ".."
$packageFullName = $packageName + '-' + $version

# Include the Chocolatey compatibility scripts if available
$thisScript = Split-Path -Parent $MyInvocation.MyCommand.Definition
$compatScript = $thisScript +  '.\chocolateyShared-Template.ps1'
if (Test-Path $compatScript) {
    . ($compatScript)
}

if ($arch -eq 'x86') {
    $osBitness     = 32
    $ghcArch       = "i386"
} else {
    $osBitness     = 64
    $ghcArch       = "x86_64"
}

# MSYS2 zips contain a root dir named msys32 or msys64
$msysName = '.' #shorten the path by exporting to the same folder
$msysRoot = Join-Path $packageDir $msysName
$msysBase = Join-Path $msysRoot ("msys" + $osBitness)

# Prepare the package parameters
$arguments = @{}

# Let's assume that the input string is something like this, and we will use a Regular Expression to parse the values
# /arc /ssh /source /hadrian /all

# Now we can use the $env:chocolateyPackageParameters inside the Chocolatey package
$packageParameters = $env:chocolateyPackageParameters

# Default the values
$useArc     = $true
$useSsh     = $false
$getSource  = $false
$useHadrian = $false
$SSH_PORT   = 22

# Now parse the packageParameters using good old regular expression
if ($packageParameters) {
  $match_pattern = "\/(?<option>([a-zA-Z]+)):(?<value>([`"'])?([a-zA-Z0-9- _\\:\.]+)([`"'])?)|\/(?<option>([a-zA-Z]+))" #" Notepad++ is confused, so fix the highlighting with this hack
  $option_name   = 'option'
  $value_name    = 'value'

  if ($packageParameters -match $match_pattern ){
      $results = $packageParameters | Select-String $match_pattern -AllMatches
      $results.matches | % {
        $arguments.Add(
            $_.Groups[$option_name].Value.Trim(),
            $_.Groups[$value_name].Value.Trim())
    }
  }
  else
  {
      Throw "Package Parameters were found but were invalid (REGEX Failure)"
  }

  # Turn off things that are only off when there are no other options specified
  $useArc = $false

  if ($arguments.ContainsKey("arc")) {
      Write-Host "Okay, I will also install and configure Arcanist."
      $useArc = $true
  }

  if ($arguments.ContainsKey("ssh")) {
      if ($arguments["ssh"] -gt 0) {
        $SSH_PORT=[convert]::ToInt32($arguments["ssh"], 10)
      }
      
      Write-Host ("Okay, I will also install and configure an SSH daemon on port " + $SSH_PORT)
      $useSsh = $true
  }
  
  if ($arguments.ContainsKey("hadrian")) {
      Write-Host "Okay, I will also install and configure a Hadrian daemon"
      $useHadrian = $true
      $getSource  = $true
  }
  
  if ($arguments.ContainsKey("source")) {
      Write-Host "Okay, I will also checkout GHC sources in ~/ghc"
      $getSource = $true
  }
  
  if ($arguments.ContainsKey("all")) {
      Write-Host "Okay, I will install and configure an SSH daemon, Hadrian and Arcanist and get the sources"
      $useArc     = $true
      $useSsh     = $true
      $useHadrian = $true
      $getSource  = $true
  }
} else {
  Write-Debug "No Package Parameters Passed in"
}

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