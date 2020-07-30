Param(
    [string]$rem_host = $(throw "Remote Host required"),
    [string]$ssh_pubk = $(throw "SSH Public Key required")
)

# Import Utilities
$OSSH_dir = (Resolve-Path -Path "C:\Program Files\*OpenSSH*" | Select-Object -ExpandProperty Path)
Import-Module $OSSH_dir\OpenSSHUtils -Force

# For normal users, not in the Administrators group
$user_ssh_dir = New-Item -ItemType Directory -Path (Join-Path $env:USERPROFILE ".ssh") -Force
If (!(Select-String -Path "$user_ssh_dir\authorized_keys" -Pattern "$ssh_pubk")) {
    Out-File -FilePath "$user_ssh_dir\authorized_keys" -InputObject "`n$ssh_pubk`n" -Append -Encoding utf8
}
Repair-AuthorizedKeyPermission -FilePath "$user_ssh_dir\authorized_keys"

# For users in the Administrators group
$admin_ssh_dir = New-Item -ItemType Directory -Path  (Join-Path $env:ProgramData "ssh") -Force
If (!(Select-String -Path "$admin_ssh_dir\administrators_authorized_keys" -Pattern "$ssh_pubk")) {
    Out-File -FilePath "$admin_ssh_dir\administrators_authorized_keys" -InputObject "`n$auth_keys`n" -Append -Encoding utf8
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

$rem_ip = [System.Net.Dns]::GetHostAddresses($rem_host)[0].IPAddressToString;

echo "Opening firewall for just $rem_host"
# Allow ES SA Rundeck only (enabled)
New-NetFirewallRule -Name "sshd_$rem_ip" -DisplayName 'OpenSSH Server (sshd) for $rem_host' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22 -RemoteAddress $rem_ip
