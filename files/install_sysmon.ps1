
#Install Sysmon
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$sysmon_installer_uri = "https://download.sysinternals.com/files/Sysmon.zip"
$sysmon_config_uri = "https://raw.githubusercontent.com/olafhartong/sysmon-modular/master/sysmonconfig.xml"
$sysmon_local_rules_filepath = "C:\Windows\sysmon.xml"

if (Test-Path "C:\Windows\Sysmon64.exe")
{
    Write-Output "Unistalling Sysmon..."
    Start-Process -WorkingDirectory "C:\Windows" -FilePath "sysmon64" -ArgumentList "-u" -Wait -NoNewWindow
}

Write-Output "Installing Sysmon..."
$sysmon_tmp_dir = "$pwd\sysmon"
if (Test-Path $sysmon_tmp_dir) {
    Remove-Item -Path $sysmon_tmp_dir -Recurse
}
New-Item -Path $sysmon_tmp_dir -Type directory | Out-Null

Invoke-WebRequest -Uri $sysmon_config_uri -OutFile $sysmon_local_rules_filepath
Invoke-WebRequest -Uri $sysmon_installer_uri -OutFile $sysmon_tmp_dir/Sysmon.zip
Expand-Archive -Path $sysmon_tmp_dir/Sysmon.zip -DestinationPath $sysmon_tmp_dir
Start-Process -WorkingDirectory $sysmon_tmp_dir -FilePath "$sysmon_tmp_dir\Sysmon64" -ArgumentList "-accepteula -i $sysmon_local_rules_filepath" -Wait -NoNewWindow

Remove-Item -Path $sysmon_tmp_dir -Recurse -Force
Write-Output "Sysmon Installation Complete"

