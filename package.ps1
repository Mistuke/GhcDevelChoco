Add-Type -assembly "system.io.compression.filesystem"

$path      = Split-Path $MyInvocation.MyCommand.Path -Parent
$bin       = Join-Path $path "bin"
$templates = Join-Path $path "templates"
$compat    = Join-Path $path "compat"
Write-Host "$bin"
ls ghc-devel*.nuspec -recurse -File | ForEach-Object { 
            $src = (Split-Path $_.FullName -Parent)
            $tmp = Join-Path $bin "tmp_build"
            $base = $_.BaseName
            New-Item $tmp -Type Directory -Force | Out-Null

            Write-Host "Packaging $_"
            
            # Copy the files over
            Copy-Item -Recurse -Force -Path (Join-Path $src "*") -Destination $tmp
            Copy-Item -Recurse -Force -Path (Join-Path $templates "*") -Destination $tmp
            Copy-Item -Recurse -Force -Path (Join-Path $compat "*") -Destination $tmp

            Remove-Item -Path $tmp -Include *.nuspec

            # Move top scripts
            $tools = Join-Path $tmp "tools"
            Move-Item (Join-Path $tools "chocolateyInstall.ps1") (Join-Path $tmp "Install.ps1")
            Move-Item (Join-Path $tools "chocolateyUninstall.ps1") (Join-Path $tmp "Uninstall.ps1")

            $source = $tmp
            $destination = Join-Path $bin ($base + '.zip')

            If(Test-path $destination) {Remove-item $destination}
            [io.compression.zipfile]::CreateFromDirectory($Source, $destination) 

            Remove-Item -Path $tmp -Recurse -Force
            Write-Host "Done packaging $base"
        }
        
cd $path

Write-Host "Done."