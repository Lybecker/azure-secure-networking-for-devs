param(
    [Parameter(Mandatory=$True)][string]$TeamName,
    [string]$Location = "westeurope"
)

$Environment = "dev"
$ResourceGroupName = "rg-${TeamName}-${Environment}"
$VnetName = "vnet-${TeamName}-${Location}-${Environment}"
$JumpboxName = "jumpbox-${TeamName}-${Environment}"
$JumpboxSubnetName = "snet-${TeamName}-shared-${Environment}"
$JumpboxAdminUsername = "jumpboxuser"
$JumpboxAdminPass = "Jumpbox123"
$BastionPublicIpAddressName = "pip-${TeamName}-bastion-${Environment}"
$BastionName = "bas-${TeamName}-${Environment}"

# TODO: Create jumpbox

Write-Output "`nCreating public IP address for Azure Bastion..."

az network public-ip create `
    --name $BastionPublicIpAddressName `
    --resource-group $ResourceGroupName `
    --location $Location `
    --sku Standard

Write-Output "`nCreating Azure Bastion resource..."

az network bastion create `
    --name $BastionName `
    --resource-group $ResourceGroupName `
    --location $Location `
    --vnet-name $VnetName `
    --public-ip-address $BastionPublicIpAddressName
