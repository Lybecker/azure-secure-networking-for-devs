#TODO

# https://learn.microsoft.com/cli/azure/network/private-endpoint?view=azure-cli-latest#az-network-private-endpoint-create

az network private-endpoint create `
    --connection-name `
    --name `
    --private-connection-resource-id `
    --resource-group `
    --subnet `
    --group-id `
    --location `
    --nic-name `
    --no-wait false `
    --vnet-name

# https://learn.microsoft.com/cli/azure/resource?view=azure-cli-latest#az-resource-update

az resource update `
    --resource-group $ResourceGroupName `
    --name $AppServiceName `
    --resource-type "Microsoft.Web/sites" `
    --set properties.publicNetworkAccess=Disabled
