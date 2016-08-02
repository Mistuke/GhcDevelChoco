# Include the shared scripts
$thisScript = Split-Path -Parent $MyInvocation.MyCommand.Definition
. ($thisScript +  '.\chocolateyShared-Template.ps1')

Write-Host "Checking if we installed an SSHd service"
$SSHServiceInstanceExistsAndIsOurs = ([bool]((Get-WmiObject win32_service | ?{$_.Name -ilike 'sshd'} | select -expand PathName) -ilike "*$msysBase*"))

if ($SSHServiceInstanceExistsAndIsOurs -eq $true) {
    execute "Removing SSHd..." `
        ('cp "' + (Join-Path $toolsDir "remove_sshd.sh") + '" ~/remove_sshd.sh && sh ~/remove_sshd.sh && rm ~/remove_sshd.sh')

    # Removing filewall rules
    netsh advfirewall firewall delete rule name='MSYS2 SSHd'
}

# Whatever chocolatey is doing during an uninstall is taking too long
# It's making this uninstall take hours which is unacceptably slow
# when all we want is to remove the files. So I'm removing the msys2
# folder manually.
Write-Host "Removing MSYS2 installation..."

Remove-Item -r -fo $msysBase