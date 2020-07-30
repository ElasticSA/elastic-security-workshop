param (
    [string]$ec_id = $(throw "ec_id is required."),
    [string]$ec_auth = $(throw "ec_auth is required.")
    [string]$stack_version = $(throw "stack_version is required")
)

$beat_config_repository_uri = "https://github.com/ElasticSA/elastic-security-workshop/blob/tj-revision/files/"

#Uninstall all Elastic Beats already installed
$app = Get-WmiObject -Class Win32_Product -Filter ("Vendor = 'Elastic'")
if ($null -ne $app) {
    Write-Output "Uninstalling exising Elastic Beats..."
    $app.Uninstall() | Out-Null
}

#Configure Beats
function ElasticBeatSetup ([string]$beat_name)
{
    Write-Output "`n*** Setting up $beat_name ****"
    $beat_install_folder = "C:\Program Files\Elastic\Beats\$stack_version\$beat_name"
    $beat_exe_path = "$beat_install_folder\$beat_name.exe"
    $beat_config_path = "C:\ProgramData\Elastic\Beats\$beat_name\$beat_name.yml"
    $beat_data_path = "C:\ProgramData\Elastic\Beats\$beat_name\data"
    $beat_config_file = "$beat_config_repository_url/$beatname.yml"
    $beat_artifact_uri = "https://artifacts.elastic.co/downloads/beats/$beat_name/$beat_name-$stack_version-windows-x86_64.msi"

    Write-Output "Installing $beat_name..."
    Invoke-WebRequest -Uri "$beat_artifact_uri" -OutFile "$pwd\$beat_name-$stack_version-windows-x86_64.msi"
    $MSIArguments = @(
        "/i"
        "$pwd\$beat_name-$stack_version-windows-x86_64.msi"
        "/qn"
        "/norestart"
        "/L"
        "$pwd\$beat_name.log"
    )
    Start-Process msiexec.exe -Wait -ArgumentList $MSIArguments -NoNewWindow

    #Download Beat configuration file
    Invoke-WebRequest -Uri "$beat_config_repository_uri/$beat_name.yml" -OutFile $beat_config_path

    # Create Beat Keystore and add CLOUD_ID and ES_PWD kqeys to it
    $params = $('-c', $beat_config_path, 'keystore','create','--force')
    & $beat_exe_path @params
    $params = $('-c', $beat_config_path, 'keystore','add','CLOUD_ID','--stdin','--force','-path.data', $beat_data_path)
    Write-Output $ec_id | & $beat_exe_path @params
    $params = $('-c', $beat_config_path, 'keystore','add','CLOUD_AUTH','--stdin','--force','-path.data', $beat_data_path)
    Write-Output $ec_auth | & $beat_exe_path @params
    
    # Run Beat Setup
    Write-Output "Running $beat_name setup..."
    $params = $('-c', $beat_config_path, 'setup', '-path.data', $beat_data_path)
    & $beat_exe_path @params

    Write-Output "Starting $beat_name Service"
    Start-Service -Name $beat_name
}
ElasticBeatSetup("winlogbeat");
ElasticBeatSetup("packetbeat");
ElasticBeatSetup("metricbeat");

Write-Output "`nBeat setup complete!"
