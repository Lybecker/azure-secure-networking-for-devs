# Tested to work with Azure CLI version 2.43.0

Param(
    [string]$Environment = "test"
)

if ($Environment -ne "dev" -and $Environment -ne "test" -and $Environment -ne "prod") {
    Write-Error "Invalid argument: Environment given was ""${Environment}"", but the valid values are: ""dev"", ""test"" or ""prod"""
    exit 1
}

Write-Output "" # Newline

try {
    Write-Output "Retrieving signed in user information..."
    $SignedInUserInformation = (az ad signed-in-user show | ConvertFrom-Json)

    Write-Output "Retrieving current subscription information..."
    $AccountInformation = (az account show | ConvertFrom-Json)
}
catch {
    Write-Error "Failed to retrieve the information of the signed in user: ${_}"
    exit -1
}

$UserObjectId = $SignedInUserInformation.id

if ($UserObjectId.Length -eq 0) {
    Write-Error "Failed to retrieve the information of the signed in user"
    exit -1
}

$UserDisplayName = $SignedInUserInformation.displayName
$UserPrincipalName = $SignedInUserInformation.userPrincipalName
$SubscriptionId = $AccountInformation.id
$SubscriptionName = $AccountInformation.name

Write-Output "`nUsing the following subscription and identity to provision resources:"
Write-Output "  - Subscription: ${SubscriptionName} (${SubscriptionId})"
Write-Output "  - Signed in user: ${UserDisplayName}`n    - User principal name: ${UserPrincipalName}`n    - Object ID: ${UserObjectId}"

$ProjectName = "puffycloud"
$Location = "westeurope"
$ResourceGroupName = "rg-${ProjectName}-network-${Location}-${Environment}"
$VnetResourceGroupName = $ResourceGroupName
$VnetName = "vnet-${ProjectName}-${Location}-${Environment}"
$JumpboxName = "jumpbox-${ProjectName}-${Environment}"
$JumpboxSubnetName = "snet-${ProjectName}-jumpbox-${Environment}"
$JumpboxAdminUsername = "jumpboxuser"
$JumpboxAdminPass = "Jumpbox123"
$BastionPublicIpAddressName = "pip-${ProjectName}-bastion-${Environment}"
$BastionName = "bas-${ProjectName}-${Environment}"

$Confirmation = Read-Host "`nAre you sure you want to proceed (y/n)?"

if ($Confirmation.ToLower() -ne 'y' -and $Confirmation.ToLower() -ne 'yes') {
    Write-Output "Aborting"
    exit 0
}

$Timestamp = Get-Date -Format "yyyyMMddHHmmss"

Write-Output "`nProvisioning jumpbox..."

az deployment group create `
    --name "jumpboxDeploymentManual${Timestamp}" `
    --resource-group $ResourceGroupName `
    --template-file ./bicep/jumpbox.bicep `
    --parameters `
        jumpboxName=$JumpboxName `
        location=$Location `
        vnetResourceGroupName=$VnetResourceGroupName `
        vnetName=$VnetName `
        subnetName=$JumpboxSubnetName `
        adminUsername=$JumpboxAdminUsername `
        adminPassword=$JumpboxAdminPass

Write-Output "`nCreating public IP address for Azure Bastion..."

az network public-ip create `
    --name $BastionPublicIpAddressName `
    --resource-group $VnetResourceGroupName `
    --location $Location `
    --sku Standard

Write-Output "`nCreating Azure Bastion resource..."

az network bastion create `
    --name $BastionName `
    --resource-group $VnetResourceGroupName `
    --location $Location `
    --vnet-name $VnetName `
    --public-ip-address $BastionPublicIpAddressName
