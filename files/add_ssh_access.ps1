Param(
    [string]$RemHost = $(throw "Remote Host required"),
    [string]$SshPubk = $(throw "SSH Public Key required")
)

# Import Utilities
$OSSH_dir = (Resolve-Path -Path "C:\Program Files\*OpenSSH*" | Select-Object -ExpandProperty Path)
Import-Module $OSSH_dir\OpenSSHUtils -Force

# For normal users, not in the Administrators group
$user_ssh_dir = New-Item -ItemType Directory -Path (Join-Path $env:USERPROFILE ".ssh") -Force
If (-Not ((Test-Path -Path "$user_ssh_dir\authorized_keys" -PathType Leaf) -And (Select-String -Path "$user_ssh_dir\authorized_keys" -SimpleMatch -Pattern "$SshPubk"))) {
    Out-File -FilePath "$user_ssh_dir\authorized_keys" -InputObject "`n$SshPubk`n" -Append -Encoding utf8
}
Repair-AuthorizedKeyPermission -FilePath "$user_ssh_dir\authorized_keys"

# For users in the Administrators group
$admin_ssh_dir = New-Item -ItemType Directory -Path  (Join-Path $env:ProgramData "ssh") -Force
If (-Not ((Test-Path -Path "$admin_ssh_dir\administrators_authorized_keys" -PathType Leaf) -And (Select-String -Path "$admin_ssh_dir\administrators_authorized_keys" -SimpleMatch -Pattern "$SshPubk"))) {
    Out-File -FilePath "$admin_ssh_dir\administrators_authorized_keys" -InputObject "`n$SshPubk`n" -Append -Encoding utf8
}

# Repair-AuthorizedKeyPermission expects to be looking in a USERPROFILE dir
# So instead, copy ssh_host_dsa_key permission object!
$myACL = Get-Acl -Path "$admin_ssh_dir\ssh_host_dsa_key"
$myACL.SetAccessRuleProtection($true, $true)
Set-Acl -Path "$admin_ssh_dir\administrators_authorized_keys" -AclObject $myACL

# Ensure we get PowerShell
$ps_location = (Get-Command powershell.exe | Select-Object -ExpandProperty Definition)
echo "Setting ssh shell to $ps_location"
Set-ItemProperty -Path "HKLM:\SOFTWARE\OpenSSH" -Name DefaultShell -Value "$ps_location" -Type String

$rem_ip = [System.Net.Dns]::GetHostAddresses($RemHost)[0].IPAddressToString;

echo "Opening firewall for just $RemHost"
# Allow ES SA Rundeck only (enabled)
if (Get-NetFirewallRule -Name "sshd_$rem_ip") {
    #Set-NetFirewallRule -Name "sshd_$rem_ip" -DisplayName "OpenSSH Server (sshd) for $RemHost" -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22 -RemoteAddress $rem_ip
}
else {
    New-NetFirewallRule -Name "sshd_$rem_ip" -DisplayName "OpenSSH Server (sshd) for $RemHost" -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22 -RemoteAddress $rem_ip
}
