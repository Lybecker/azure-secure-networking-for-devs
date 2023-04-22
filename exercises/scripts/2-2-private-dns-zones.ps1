param(
    [Parameter(Mandatory=$True)][string]$TeamName,
    [string]$PrimaryLocation = "westeurope",
    [string]$SecondaryLocation = "eastus",
    [string]$SharedLocation = "swedencentral"
)

$Environment = "dev"
$ResourceGroupName = "rg-${TeamName}-${Environment}"
$StorageSuffix = "core.windows.net"

$PrivateDnsZoneNames = @(
    "privatelink.azurewebsites.net",
    "privatelink.blob.${StorageSuffix}" #,
    #"privatelink.vaultcore.azure.net"
)

$VnetNames = @(
    "vnet-${TeamName}-${Environment}-${SharedLocation}",
    "vnet-${TeamName}-${Environment}-${PrimaryLocation}",
    "vnet-${TeamName}-${Environment}-${SecondaryLocation}"
)

foreach ($PrivateDnsZoneName in $PrivateDnsZoneNames) {
    Write-Output "`nCreating private DNS zone ${PrivateDnsZoneName}..."
    # https://learn.microsoft.com/cli/azure/network/private-dns/zone?view=azure-cli-latest#az-network-private-dns-zone-create

    az network private-dns zone create --name $PrivateDnsZoneName --resource-group $ResourceGroupName

    foreach ($VnetName in $VnetNames) {
        Write-Output "`nCreating virtual network link for network ${VnetName} to private DNS zone ${PrivateDnsZoneName}..."
        # https://learn.microsoft.com/en-us/cli/azure/network/private-dns/link/vnet?view=azure-cli-latest#az-network-private-dns-link-vnet-create

        $VnetLinkName = "${VnetName}-${PrivateDnsZoneName}".Replace(".", "-")

        az network private-dns link vnet create `
            --name $VnetLinkName `
            --registration-enabled false `
            --resource-group $ResourceGroupName `
            --virtual-network $VnetName `
            --zone-name $PrivateDnsZoneName
    }
}
