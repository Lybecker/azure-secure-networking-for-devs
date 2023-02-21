param(
    [Parameter(Mandatory=$True)][string]$TeamName,
    [string]$Location = "westeurope"
)

$Environment = "dev"
$ResourceGroupName = "rg-${TeamName}-${Environment}"
$VnetName = "vnet-${TeamName}-${Location}-${Environment}"
$JumpboxNsgName = "nsg-${TeamName}-jumpbox-${Environment}"
$JumpboxNicName = "nic-${TeamName}-jumpbox-${Environment}"
$JumpboxVmName = "vm${TeamName}"
$JumpboxVmImage = "MicrosoftWindowsDesktop:Windows-11:win11-22h2-pro:22621.1265.230207" # URN format for '--image': "Publisher:Offer:Sku:Version"
$JumpboxSubnetName = "snet-${TeamName}-shared-${Environment}"
$JumpboxAdminUsername = "jumpboxuser"
$JumpboxAdminPassword = "JumpboxPassword123!"
$BastionPublicIpAddressName = "pip-${TeamName}-bastion-${Environment}"
$BastionName = "bas-${TeamName}-${Environment}"

Write-Output "`nCreating network security group (NSG) for jumpbox..."

az network nsg create --name $JumpboxNsgName --resource-group $ResourceGroupName

Write-Output "`nCreating rule to deny all inbound traffic for NSG..."
# Update Azure CLI (az upgrade) in case running into this bug: https://github.com/Azure/azure-cli/issues/24939

az network nsg rule create `
    --name "DenyAllInbound" `
    --resource-group $ResourceGroupName `
    --nsg-name $JumpboxNsgName `
    --priority "200" `
    --access "Deny" `
    --description "Denies all inbound traffic" `
    --direction "Inbound" `
    --protocol "*"

Write-Output "`nCreating network interface (NIC) for jumpbox..."

az network nic create `
    --name $JumpboxNicName `
    --resource-group $ResourceGroupName `
    --location $Location `
    --vnet-name $VnetName `
    --subnet $JumpboxSubnetName `
    --network-security-group $JumpboxNsgName

Write-Output "`nCreating jumpbox VM..."

az vm create `
    --name $JumpboxVmName `
    --resource-group $ResourceGroupName `
    --image $JumpboxVmImage `
    --admin-username $JumpboxAdminUsername `
    --admin-password $JumpboxAdminPassword `
    --nics $JumpboxNicName

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
