
# WARNING
# DO NOT USE THIS TO INSTALL ON Win Server 2019+ or Win 10 1809+
# INSTEAD: https://docs.microsoft.com/en-us/windows-server/administration/openssh/openssh_install_firstuse#installing-openssh-from-the-settings-ui-on-windows-server-2019-or-windows-10-1809

# Open the SSH server to the world?
$enable_fw_rule = "False"

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Get Win-OpenSSH download url; thanks: https://github.com/PowerShell/Win32-OpenSSH/wiki/How-to-retrieve-links-to-latest-packages
$request = [System.Net.WebRequest]::Create('https://github.com/PowerShell/Win32-OpenSSH/releases/latest/')
$request.AllowAutoRedirect=$false
$response=$request.GetResponse()
$wossh_url = $([String]$response.GetResponseHeader("Location")).Replace('tag','download') + '/OpenSSH-Win64.zip' 

echo "Downloading $wossh_url"
Invoke-WebRequest -Uri $wossh_url -OutFile "$pwd\OpenSSH-Win64.zip"

echo "Extracting files"
Expand-Archive -Path "$pwd\OpenSSH-Win64.zip" -DestinationPath "C:\Program Files\" -Force

echo "Installing service"
powershell.exe -ExecutionPolicy Bypass -File "C:\Program Files\OpenSSH-Win64\install-sshd.ps1"

echo "Adding firewall"
New-NetFirewallRule -Name sshd_any -DisplayName 'OpenSSH Server (sshd)' -Enabled $enable_fw_rule -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22

echo "Starting service"
Set-Service sshd -StartupType Automatic
Start-Service -Name sshd
