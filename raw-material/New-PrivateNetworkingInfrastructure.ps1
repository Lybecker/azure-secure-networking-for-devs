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

Write-Output "`nUsing the following identity and subscription to provision private networking infrastructure:"
Write-Output "  - Signed in user: ${UserDisplayName}`n    - User principal name: ${UserPrincipalName}`n    - Object ID: ${UserObjectId}"
Write-Output "  - Subscription: ${SubscriptionName} (${SubscriptionId})"

$ProjectName = "puffycloud"
$Locations = "westeurope", "swedencentral" # The first one is where the bulk of the shared resources will go
$SubnetResourceNamePrefix = "snet-"

$Confirmation = Read-Host "`nAre you sure you want to proceed (y/n)?"

if ($Confirmation.ToLower() -ne 'y' -and $Confirmation.ToLower() -ne 'yes') {
    Write-Output "Aborting"
    exit 0
}

$ResourceGroupNames = @()
$VnetNames = @()
$VnetIds = @()
$IpIncrement = 0

foreach ($Location in $Locations) {
    $ResourceGroupName = "rg-${ProjectName}-network-${Location}-${Environment}"
    $ResourceGroupNames += $ResourceGroupName
    $VnetName = "vnet-${ProjectName}-${Location}-${Environment}"
    $VnetNames += $VnetName

    Write-Output "`nCreating resource group ${ResourceGroupName}..."
    az group create --name $ResourceGroupName --location $Location

    $VnetAddressPrefixes = "10.0.${IpIncrement}.0/22"
    Write-Output "`nCreating virtual network ${VnetName} in resource group ${ResourceGroupName} with address prefixes ${VnetAddressPrefixes}..."

    az network vnet create `
        --name $VnetName `
        --location $Location `
        --resource-group $ResourceGroupName `
        --address-prefixes $VnetAddressPrefixes

    $VnetIds += (az network vnet show --name $VnetName --resource-group $ResourceGroupName | ConvertFrom-Json).id

    Write-Output "`nCreating subnet for Batch in virtual network ${VnetName}..."

    az network vnet subnet create `
        --name "${SubnetResourceNamePrefix}${ProjectName}-batch-${Location}-${Environment}" `
        --resource-group $ResourceGroupName `
        --vnet-name $VnetName `
        --address-prefixes "10.0.${IpIncrement}.0/26" `
        --disable-private-endpoint-network-policies false `
        --disable-private-link-service-network-policies false `
        --service-endpoints Microsoft.KeyVault Microsoft.Storage

    Write-Output "`nCreating subnet for shared resources in virtual network ${VnetName}..."

    az network vnet subnet create `
        --name "${SubnetResourceNamePrefix}${ProjectName}-shared-${Environment}" `
        --resource-group $ResourceGroupName `
        --vnet-name $VnetName `
        --address-prefixes "10.0.${IpIncrement}.64/26" `
        --disable-private-endpoint-network-policies false `
        --disable-private-link-service-network-policies false `
        --service-endpoints Microsoft.KeyVault Microsoft.Storage

    if ($Location -eq $Locations[0]) {
        Write-Output "`nVirtual network ${VnetName} will contain the shared, core resources"

        Write-Output "`nCreating subnet for Bastion in virtual network ${VnetName}..."

        az network vnet subnet create `
            --name "AzureBastionSubnet" `
            --resource-group $ResourceGroupName `
            --vnet-name $VnetName `
            --address-prefixes "10.0.${IpIncrement}.128/26" `
            --disable-private-endpoint-network-policies false `
            --disable-private-link-service-network-policies false

        Write-Output "`nCreating subnet for apps in virtual network ${VnetName}..."

        az network vnet subnet create `
            --name "${SubnetResourceNamePrefix}${ProjectName}-apps-${Environment}" `
            --resource-group $ResourceGroupName `
            --vnet-name $VnetName `
            --address-prefixes "10.0.${IpIncrement}.192/26" `
            --delegations Microsoft.Web/serverFarms `
            --disable-private-endpoint-network-policies false `
            --disable-private-link-service-network-policies false `
            --service-endpoints Microsoft.Web

        Write-Output "`nCreating subnet for jumpbox in virtual network ${VnetName}..."

        az network vnet subnet create `
            --name "${SubnetResourceNamePrefix}${ProjectName}-jumpbox-${Environment}" `
            --resource-group $ResourceGroupName `
            --vnet-name $VnetName `
            --address-prefixes "10.0.$($IpIncrement + 1).0/26" `
            --disable-private-endpoint-network-policies false `
            --disable-private-link-service-network-policies false
    }

    $IpIncrement += 4
}

Write-Output "`nPeering $($VnetIds.Count) virtual networks..."

for ($i = 0; $i -lt $VnetIds.Count; $i++) {
    for ($j = 0; $j -lt $VnetIds.Count; $j++) {
        if ($i -eq $j) {
            continue
        }

        Write-Output "Peering $($VnetNames[$i]) <-> $($VnetNames[$j])..."

        az network vnet peering create `
            --name "peer-$($VnetNames[$i])-$($VnetNames[$j])" `
            --resource-group $($ResourceGroupNames[$i]) `
            --vnet-name $($VnetNames[$i]) `
            --remote-vnet $($VnetIds[$j]) `
            --allow-vnet-access
    }
}

Write-Output "`nDone!"
