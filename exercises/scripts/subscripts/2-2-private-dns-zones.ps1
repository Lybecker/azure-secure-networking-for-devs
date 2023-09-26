param(
    [Parameter(Mandatory=$True)][string]$TeamName,
    [string]$EuLocation = "westeurope",
    [string]$UsLocation = "eastus",
    [string]$HubLocation = "swedencentral"
)

$Environment = "dev"
$ResourceGroupNameHub = "rg-hub-${TeamName}-${Environment}"
$ResourceGroupNames = @($ResourceGroupNameHub, "rg-${TeamName}-${Environment}-eu", "rg-${TeamName}-${Environment}-us")
$StorageSuffix = "core.windows.net"

$PrivateDnsZoneNames = @(
    "privatelink.azurewebsites.net",
    "privatelink.blob.${StorageSuffix}" #,
    #"privatelink.vaultcore.azure.net"
)

$VnetNames = @(
    "vnet-${TeamName}-${Environment}-${HubLocation}",
    "vnet-${TeamName}-${Environment}-${EuLocation}",
    "vnet-${TeamName}-${Environment}-${UsLocation}"
)

foreach ($PrivateDnsZoneName in $PrivateDnsZoneNames) {
    Write-Output "`nCreating private DNS zone ${PrivateDnsZoneName}..."
    # https://learn.microsoft.com/cli/azure/network/private-dns/zone?view=azure-cli-latest#az-network-private-dns-zone-create

    az network private-dns zone create --name $PrivateDnsZoneName --resource-group $ResourceGroupNameHub

    for ($i = 0; $i -lt 3; $i++) {
        $VnetName = $VnetNames[$i]
        $ResourceGroupName = $ResourceGroupNames[$i]
        $VnetId = (az network vnet show --name $VnetName --resource-group $ResourceGroupName --query id --output tsv)

        Write-Output "`nCreating virtual network link for network ${VnetName} (resource group ${ResourceGroupName}) to private DNS zone ${PrivateDnsZoneName}..."
        Write-Output "VNET ID: ${VnetId}"

        # https://learn.microsoft.com/en-us/cli/azure/network/private-dns/link/vnet?view=azure-cli-latest#az-network-private-dns-link-vnet-create

        $VnetLinkName = "${VnetName}-${PrivateDnsZoneName}".Replace(".", "-")

        az network private-dns link vnet create `
            --name $VnetLinkName `
            --registration-enabled false `
            --resource-group $ResourceGroupNameHub `
            --virtual-network $VnetId `
            --zone-name $PrivateDnsZoneName
    }
}
