#!/bin/sh
#
#  msys2-sshd-setup.sh — configure sshd on MSYS2 and run it as a Windows service
#
#  Please report issues and/or improvements to Sam Hocevar <sam@hocevar.net>
#  Script gotten from https://gist.github.com/samhocevar/00eec26d9e9988d080ac
#
#  Prerequisites:
#    — MSYS2 itself: http://sourceforge.net/projects/msys2/
#    — admin tools: pacman -S openssh cygrunsrv mingw-w64-x86_64-editrights
#
#  This script is a cleaned up and improved version of the procedure initially
#  found at https://ghc.haskell.org/trac/ghc/wiki/Building/Windows/SSHD
#
#  Changelog:
#   24 Aug 2015 — run server with -e to redirect logs to /var/log/sshd.log
#

set -e

#
# Configuration
#

if [ -f ~/.sshd_installed ] then
    echo "SSHd installation found. Removing.."
    # Stop and unregister service with cygrunsrv

    # Remove sshd service
    cygrunsrv --stop sshd
    cygrunsrv --remove sshd

    # Delete any sshd or related users (such as sshd_server) from the system
    net user sshd /delete
    net user sshd_server /delete
fi