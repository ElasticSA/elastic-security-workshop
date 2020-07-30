

$auth_keys = @"
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDmg54/JaaDIiemlLV/Gmr/K4RA5CcUWUgOOPTFrxL9uJ4e7U+pl5+F9inqxpYfiZclnJb2J8ThNs8Y0popLj3KKZ6EdyeDIRkUgDzce2JHXTXc/NkySEI929yDA1nyj7Rs/5Rza4ROVo6U7ySOJ7hIY876roUC7z7eMVxEeRqynDweebX5jymgSFT8XWSe85Id5d6hm0Z3jcgfNj+d+JNJdvR1Jt4MKci5JQFRPzaiizUw/408jHUf3P5n9sM7J+Xs6ih2ze7a+TP0iZWec//ngEupdYp8aT2k03SKFqL62m+My4dDb+WrJx8fRfEayWgSaoieofrXbumtGAvSiVSS1YLn1Uk5CfBd4hwIeYfNAEt2c7ahdLyeSGMECjy3e9Sltjg8pnpdwdMMwh13vfu4XYlWOWoKgKn6SsFvG2wEnwt6mUkgMZ1ahVKtN7rZ8600/rmXDfJFkIQFGMpA+K5/E2or1P1SPQzH9RhsafALJb9qjgvAQyoTK/UfJZWWDSM= thorbenj@elastic.co/Violone

ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDJVLPTFS3NwCD9WaIr2eiCG5kDlceknL/BsXww4KMcdNv1eTwwZTVV+8Vi8VRjIJDPyoRgx9akjpVqvCbb5TBoErcXL7UgQCu2P+KptNB6c0qSF1q31HNWWfuZ1UoLtPLobE3pCsCQHL/mj1El/iL1gqdHv21Wlf2XNyC67mm81JxxPoppJoX6ohpF01n327/HjGS9/s5jEba3eN7eNB3fZpr9HF4Mmkmax4SlT+qyQiIOAnEILFFMx5bJIFquKFnDV2wf1JnbZFX4iPooLdYpXvlw1uL9zJJ8nt+HArMQ4Nux/WgdgL2dC4z0I3gKNFXWuBaj0Pn7SmlIO01y1Y04sDEGqF0s7V66J4NhLv0/yAYFbYbEmi8QpH7cNxoLliPFFws/R/HbgbdMzFDx8UsFwClGsYIymSB7RFm2C8EEWXnI1OA6ZBpUxLRkLEatMZ0hKfx2aqQACBQEJTcgua6nT5+hv9IJROoahpYn2UEX3R8shr57oxM32FBn6QFLvWlZwYG/LzuzCotXKPBIQhJ3WU3O/nVDrVSi5VMzAHlwW20KatJb8vvx3Dahv0XJwdPcWsz15W/57LGfwDxQv9qNmF0rLhnfwPHJzA57uAFsdLaj4wse/nsaCYNp48Emko0fRn663F5GFFQF+CtUDmnhCLJbiCVCg7jGd0JJ9MMbOQ== rundeck@ElasticSA

"@

$rd_host = "rd.elasticsa.co"

# Import Utilities
$OSSH_dir = (Resolve-Path -Path "C:\Program Files\*OpenSSH*" | Select-Object -ExpandProperty Path)
Import-Module $OSSH_dir\OpenSSHUtils -Force

# For normal users, not in the Administrators group
$user_ssh_dir = New-Item -ItemType Directory -Path (Join-Path $env:USERPROFILE ".ssh") -Force
Out-File -FilePath "$user_ssh_dir\authorized_keys" -InputObject $auth_keys -Encoding utf8
Repair-AuthorizedKeyPermission -FilePath "$user_ssh_dir\authorized_keys"

# For users in the Administrators group
$admin_ssh_dir = New-Item -ItemType Directory -Path  (Join-Path $env:ProgramData "ssh") -Force
Out-File -FilePath "$admin_ssh_dir\administrators_authorized_keys" -InputObject $auth_keys -Encoding utf8

# Repair-AuthorizedKeyPermission expects to be looking in a USERPROFILE dir
# So copy ssh_host_dsa_key permission object!
$myACL = Get-Acl -Path "$admin_ssh_dir\ssh_host_dsa_key"
$myACL.SetAccessRuleProtection($true, $true)
Set-Acl -Path "$admin_ssh_dir\administrators_authorized_keys" -AclObject $myACL

# Ensure we get PowerShell
$ps_location = (Get-Command powershell.exe | Select-Object -ExpandProperty Definition)
echo "Setting ssh shell to $ps_location"
Set-ItemProperty -Path "HKLM:\SOFTWARE\OpenSSH" -Name DefaultShell -Value "$ps_location" -Type String

$rd_ip = [System.Net.Dns]::GetHostAddresses($rd_host)[0].IPAddressToString;

echo "Opening firewall for just RD"
# Allow ES SA Rundeck only (enabled)
New-NetFirewallRule -Name sshd1 -DisplayName 'OpenSSH Server (sshd) for RD' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22 -RemoteAddress $rd_ip
