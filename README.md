# GhcDevelChoco
Chocolatey sources for quick and easy setup of a GHC development environment on Windows.

This package has two modes of operation, one that uses Chocolatey as its backing and one
that uses self contained powershell package as it's base.

To build the chocolatey package run `.\build-chocolatey-packages.ps1` and to build the
standalone package run `.\build-standalone-packages.ps1`. The results will be placed in the
newly created `bin` folder.

## Standalone Install instructions

To use the standalone package, unzip the version you want to use and call `./Install.ps1 <location> <options>`

E.g.

    ./Install.ps1 C:\ghc-dev\ /source /arc /hadrian

See below for a description of the arguments. 

    NOTE: *This release has a noted limitation. If you install the SSH deamon (which requires you to run the
          install script using an elevated powershell console!) then you need to manually run `remove_sshd.sh`
          before calling `./Remove.ps1` because the ssh deamon is not properly being detected in this version.*
          
          If you forget, you can manually execute the instructions in `remove_sshd.sh` later (using sc.exe to unregister
          the service).

## Chocolatey Install instructions

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
