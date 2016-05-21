# GhcDevelChoco
Chocolatey sources for quick and easy setup of a GHC development environment on Windows.

This repository contains the sources for the GHC Development Chocolatey packages.

To use these get Chocolatey https://chocolatey.org/

and then just install the version of GHC Devel you want.

    cinst ghc-devel-{x86|x64}
    
for the latest version

    cinst ghc-devel-{x86|x64} -pre 
    
for the latest pre-release version

    cinst ghc-devel-{x86|x64} -version 1.0.0
    
for  specific version, e.g. `1.0.0`

The installer does not support switching between `x86` and `x86_64`. This is because it is often
needed to be able to run both versions side by side. Because of this the versions have been
separated into different packages.

uninstalling can be done with
    
    cuninst ghc-devel-{x86|x64}
    
If more than one version of `GHC Devel` is present then you will be presented with prompt on which version you
would like to install.

     Note: Unfortunately because of a how Chocolatey currently works, you will have 
           to restart the console in order for the PATH variables to be correct. 
           The current section cannot be updated.
