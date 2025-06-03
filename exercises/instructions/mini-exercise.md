# Virtual networks

Let's start simple. Your mission, should you choose to accept it, is to create a secure virtual network. The virtual network will form a network boundary around the Azure resource assigned to them, allowing you to control all traffic to and from.

Use the recommended names below as per [Abbreviation examples for Azure resources](https://learn.microsoft.com/azure/cloud-adoption-framework/ready/azure-best-practices/resource-abbreviations) and create:

1. `vnet-{team name}-dev-eu` e.g., `vnet-myteam-dev-eu` in Sweden Central

If you have time left over, debate the existentialism of virtual networks. Are they real? Am I?

## Tips and tricks

### Learning resources

* [What is Azure Virtual Network?](https://learn.microsoft.com/azure/virtual-network/virtual-networks-overview)
* [Quickstart: Use the Azure portal to create a virtual network](https://learn.microsoft.com/azure/virtual-network/quick-create-portal)

### Relevant Azure CLI commands

* [az network vnet create](https://learn.microsoft.com/cli/azure/network/vnet?view=azure-cli-latest#az-network-vnet-create)

### Tools

* [CIDR to IPv4 Conversion](https://www.ipaddressguide.com/cidr)

# Subnets

Our virtual network sure feel empty and sad. Let's cheer them up by giving them subnets!

1. `snet-default-{team name}-dev-eu`, with the range of 128 addresses
1. `snet-apps-{team name}-dev-eu` with the range of 128 addresses
    * Delegate this subnet for `Microsoft.Web/serverFarms`

> The `default` subnet is for any kind of Azure resources. The `apps` subnet is delegated to Azure web apps, meaning you cannot use it for anything else.

## Private DNS zones

Now, on to some D-N-S-ing (if that's not a word, it darn well should be).

1. Create two [private DNS zones](https://learn.microsoft.com/azure/dns/private-dns-privatednszone), in the **hub resource group**, for:
    1. Web apps ("`privatelink.azurewebsites.net`")
    1. Blob storages ("`privatelink.blob.core.windows.net`")

    > DNS zones are a global resource, so you only need to create them once, but they need to reside in a resource group.

1. Link the created DNS zones to the virtual network with [virtual network links](https://learn.microsoft.com/azure/dns/private-dns-virtual-network-links)
    * There's no official naming recommendation, but this one works: `<Virtual network name>-<DNS zone name>` with dots replaced with dashes e.g., `vnet-{team name}-dev-eu-privatelink-azurewebsites-net`

## Private endpoints

The private networks and DNS zones will do us no good, if they are not used. It would be a terrible waste to just leave them collecting dust. Get the point? Get it? Like the end... **point**! My mom thinks I'm funny.

For storage accounts and web app services:

1. Create [private endpoints](https://learn.microsoft.com/azure/private-link/private-endpoint-overview)

    > Use the following resource name pattern:
    >
    > * Private endpoint name: `pep-{resource name}` e.g., for the hub storage account `pep-st{team name}devhub`
    > * Network interface name: `nic-pep-{resource name}`

1. Add [private DNS zone records](https://learn.microsoft.com/azure/private-link/private-endpoint-dns#private-dns-zone-group) for the endpoints
1. Link the private endpoints to appropriate virtual networks and subnets

> **Note:** Azure web apps are a little bit special. They have private endpoints and VNET integration. Don't worry, you will figure it out!

## Disable access and enable web app VNET integration

All the hard work is done, but we are not quite finished yet. We created virtual networks and private endpoints for the Azure resources to protect them from the prying eyes of the public internet.

Now, disable public internet access to app services and storage accounts:

<!-- 1. The access to the storage accounts should be only allowed from the virtual network they are in -->
1. The public access to all three storage accounts should be disabled
1. The app services should have access restrictions and private endpoints **on**

Enable the virtual network (VNET) integration for the outbound traffic. No traffic should ever leave the virtual networks.

## Tips and tricks

### Learning resources

* [Add, change, or delete a virtual network subnet](https://learn.microsoft.com/azure/virtual-network/virtual-network-manage-subnet?tabs=azure-portal)
* [What is a private Azure DNS zone?](https://learn.microsoft.com/azure/dns/private-dns-privatednszone)
* [What is a private endpoint?](https://learn.microsoft.com/azure/private-link/private-endpoint-overview)

### Relevant Azure CLI commands

* [az-network-vnet-subnet-create](https://learn.microsoft.com/cli/azure/network/vnet/subnet?view=azure-cli-latest#az-network-vnet-subnet-create)
* [az network private-dns zone create](https://learn.microsoft.com/cli/azure/network/private-dns/zone?view=azure-cli-latest#az-network-private-dns-zone-create)
* [az network private-dns link vnet create](https://learn.microsoft.com/en-us/cli/azure/network/private-dns/link/vnet?view=azure-cli-latest#az-network-private-dns-link-vnet-create)
* [az network private-endpoint create](https://learn.microsoft.com/cli/azure/network/private-endpoint?view=azure-cli-latest#az-network-private-endpoint-create)
* [az network private-endpoint dns-zone-group add](https://learn.microsoft.com/en-us/cli/azure/network/private-endpoint/dns-zone-group?view=azure-cli-latest#az-network-private-endpoint-dns-zone-group-add)
* [az resource update](https://learn.microsoft.com/cli/azure/resource?view=azure-cli-latest#az-resource-update)
* [az webapp vnet-integration add](https://learn.microsoft.com/cli/azure/webapp/vnet-integration?view=azure-cli-latest#az-webapp-vnet-integration-add)
