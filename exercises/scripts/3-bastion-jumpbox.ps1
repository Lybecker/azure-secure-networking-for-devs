param(
    [Parameter(Mandatory=$True)][string]$TeamName,
    [string]$Location = "swedencentral"
)

$Environment = "dev"
$ResourceGroupName = "rg-${TeamName}-${Environment}"
$VnetName = "vnet-${TeamName}-${Environment}-${Location}"
$JumpboxNsgName = "nsg-jumpbox-${TeamName}-${Environment}"
$JumpboxNicName = "nic-jumpbox-${TeamName}-${Environment}"
$JumpboxVmName = "vm${TeamName}"
$JumpboxVmImage = "MicrosoftWindowsDesktop:Windows-11:win11-22h2-pro:22621.1265.230207" # URN format for '--image': "Publisher:Offer:Sku:Version"
$JumpboxSubnetName = "snet-shared-${TeamName}-${Environment}-${Location}"
$JumpboxAdminUsername = "jumpboxuser"
$JumpboxAdminPassword = "JumpboxPassword123!"
$BastionPublicIpAddressName = "pip-bastion-${TeamName}-${Environment}"
$BastionName = "bas-${TeamName}-${Environment}"

.\2-1-subnet.ps1 $TeamName $Location "bastion" "10.0.0.64/26"

Write-Output "`nCreating network security group (NSG) for jumpbox..."
# https://learn.microsoft.com/cli/azure/network/nsg?view=azure-cli-latest#az-network-nsg-create

az network nsg create `
    --name $JumpboxNsgName `
    --resource-group $ResourceGroupName `
    --location $Location `
    --no-wait false

Write-Output "`nCreating rule to deny all inbound traffic for NSG..."
# Update Azure CLI (az upgrade) in case running into this bug: https://github.com/Azure/azure-cli/issues/24939
# https://learn.microsoft.com/cli/azure/network/nsg/rule?view=azure-cli-latest#az-network-nsg-rule-create

az network nsg rule create `
    --name "DenyAllInbound" `
    --resource-group $ResourceGroupName `
    --nsg-name $JumpboxNsgName `
    --priority "200" `
    --access "Deny" `
    --description "Denies all inbound traffic" `
    --direction "Inbound" `
    --protocol "*" `
    --no-wait false

Write-Output "`nCreating network interface (NIC) for jumpbox..."
# https://learn.microsoft.com/cli/azure/network/nic?view=azure-cli-latest#az-network-nic-create

az network nic create `
    --name $JumpboxNicName `
    --resource-group $ResourceGroupName `
    --location $Location `
    --vnet-name $VnetName `
    --subnet $JumpboxSubnetName `
    --network-security-group $JumpboxNsgName

Write-Output "`nCreating jumpbox VM..."
# https://learn.microsoft.com/cli/azure/vm?view=azure-cli-latest#az-vm-create

az vm create `
    --name $JumpboxVmName `
    --resource-group $ResourceGroupName `
    --location $Location `
    --image $JumpboxVmImage `
    --admin-username $JumpboxAdminUsername `
    --admin-password $JumpboxAdminPassword `
    --nics $JumpboxNicName

Write-Output "`nCreating public IP address for Azure Bastion..."
# https://learn.microsoft.com/cli/azure/network/public-ip?view=azure-cli-latest#az-network-public-ip-create

az network public-ip create `
    --name $BastionPublicIpAddressName `
    --resource-group $ResourceGroupName `
    --location $Location `
    --sku Standard

Write-Output "`nCreating Azure Bastion resource..."
# https://learn.microsoft.com/cli/azure/network/bastion?view=azure-cli-latest#az-network-bastion-create

az network bastion create `
    --name $BastionName `
    --resource-group $ResourceGroupName `
    --location $Location `
    --vnet-name $VnetName `
    --public-ip-address $BastionPublicIpAddressName
