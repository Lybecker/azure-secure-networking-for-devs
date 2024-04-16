param(
    [Parameter(Mandatory=$True)][string]$TeamName,
    [Parameter(Mandatory=$True)][string]$Location,
    [Parameter(Mandatory=$True)][string]$ResourceGroupName,
    [Parameter(Mandatory=$True)][string]$SubnetId,  # Used in the name to identify the purpose e.g., "apps"
    [string]$AdditionalArguments = ""
)

$Environment = "dev"
$NicName = "nic-${SubnetId}-${TeamName}-${Environment}-${Location}"
$VmName = "vm${TeamName}${Environment}"

Write-Output "`nCreating vm ${VmName} attached with Nic ${NicName}..."
# https://learn.microsoft.com/en-gb/cli/azure/vm?view=azure-cli-latest#az-vm-create()

$Command = "az vm create --name ${VmName} --resource-group ${ResourceGroupName} --location ${Location} --image Ubuntu2204 --nics ${NicName} --generate-ssh-keys"
Invoke-Expression $Command