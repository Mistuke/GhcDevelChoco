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

for specific version, e.g. `1.0.0`

The installer does not support switching between `x86` and `x86_64`. This is because it is often
needed to be able to run both versions side by side. Because of this the versions have been
separated into different packages.

uninstalling can be done with

    cuninst ghc-devel-{x86|x64}

If more than one version of `GHC Devel` is present then you will be presented with prompt on which version you
would like to install.

This package does however support automatically configuring arcanist and an ssh server for you.

#### Package Parameters
The following package parameters can be set:

 * `/arc`     - this will configure the phabricator tool `arc` for use. This is done by default if no params are specified.
 * `/ssh`     - this installs and configures an ssh server for use with this environment, this services will be started automatically by Windows. This is not enabled by default.
 * `/source`  - this will automatically check out ghc into a folder ~\ghc. This is not enabled by default.
 * `/hadrian` - this will automatically check out hadrian in the ghc folder. This is not enabled by default, if enabled it implies `/source`.
 * `/all`     - this flag will do all the above. This is not enabled by default.

These parameters can be passed to the installer with the use of `-params`.
For example: `-params '"/arc /ssh"'`.

A full command looks like

    choco install -y ghc-devel-{x86|x64} -params "/arc"

To start the package, run `ghc-devel-{x86|x64}.cmd`

     Note: Unfortunately because of a how Chocolatey currently works, you will have 
           to restart the console in order for the PATH variables to be correct. 
           The current section cannot be updated.
