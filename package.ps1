Add-Type -assembly "system.io.compression.filesystem"

$path      = Split-Path $MyInvocation.MyCommand.Path -Parent
$bin       = Join-Path $path "bin"
$templates = Join-Path $path "templates"
$compat    = Join-Path $path "compat"
Write-Host "$bin"
ls ghc-devel*.nuspec -recurse -File | ForEach-Object { 
            $src = (Split-Path $_.FullName -Parent)
            $tmp = Join-Path $bin "tmp_build"
            New-Item $tmp

            Write-Host "Packaging $_"
            
            # Copy the files over
            Copy-Item -Recurse -Force -Path $src -Include * -Destination $tmp
            Copy-Item -Recurse -Force -Path $templates -Include * -Destination $tmp
            Copy-Item -Recurse -Force -Path $compat -Include * -Destination $tmp
            
            Remove-Item -Path $tmp -Filter *.nupkg
            
            $source = $tmp
            $destination = Join-Path $bin ($_.BaseName + '.zip')

            If(Test-path $destination) {Remove-item $destination}
            [io.compression.zipfile]::CreateFromDirectory($Source, $destination) 
            
            cd $dir
            choco pack
            Remove-Item -Path $tmp -Recurse -Force
            Write-Host "Done packging $_.BaseName"
        }
        
cd $path

Write-Host "Done."