param(
    [Parameter(Mandatory=$True)][string]$TeamName
)

$ResourceGroupNames = @($env:ASNFD_RESOURCE_GROUP_NAME_EU, $env:ASNFD_RESOURCE_GROUP_NAME_US)
$AppServiceNames = @($env:ASNFD_APP_SERVICE_NAME_EU, $env:ASNFD_APP_SERVICE_NAME_US)
$VnetNames = @($env:ASNFD_VNET_NAME_EU, $env:ASNFD_VNET_NAME_US)
$SubnetNames = @($env:ASNFD_APPS_SNET_NAME_EU, $env:ASNFD_APPS_SNET_NAME_US)


for ($i = 0; $i -lt 2; $i++) {
    $ResourceGroupName = $ResourceGroupNames[$i]
    $AppServiceName = $AppServiceNames[$i]
    $VnetName = $VnetNames[$i]
    $SubnetName = $SubnetNames[$i]

    Write-Output "`nAdding VNET integration for app service ${AppServiceName} using virtual network and subnet ${VnetName}/${SubnetName}..."
    # https://learn.microsoft.com/cli/azure/webapp/vnet-integration?view=azure-cli-latest#az-webapp-vnet-integration-add()

    az webapp vnet-integration add `
        --name $AppServiceName `
        --resource-group $ResourceGroupName `
        --subnet $SubnetName `
        --vnet $VnetName `
        --skip-delegation-check false
}
