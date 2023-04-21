# Some privacy, please!

> *(With trailer man sound) Previously on Azure secure networking exercise...*
>
> In case you need to catch up, run the script to get to where we need to be now:
>
> ```ps1
> .\1-vnets.ps1 -TeamName <your team name>
> ```

## Subnets

Our virtual networks sure feel empty and sad. Let's cheer them up by giving them subnets!

1. In the "shared" virtual network - the one in North Europe - create the following two subnets:
    1. Subnet for Azure Bastion - the name and size need to be specific and you must figure out what they are
    1. `snet-shared-{team name}-dev-northeurope`, span of 64 IP addresses should be plenty for our needs
        <!-- * Add service endpoint for storage -->
1. In the both two other virtual networks, create:
    1. `snet-shared-{team name}-dev-{location}` with the range of 128 addresses
        <!-- * Add service endpoint for storage -->
    1. `snet-apps-{team name}-dev-{location}` with the range of 128 addresses
        * Delegate this subnet for `Microsoft.Web/serverFarms`

## Private DNS zones

Now, on to some D-N-S-ing (if that's not a word, it darn well should be).

1. Create two [private DNS zones](https://learn.microsoft.com/azure/dns/private-dns-privatednszone) for:
    1. Web apps ("`privatelink.azurewebsites.net`")
    1. Blob storages
1. Link the created DNS zones to all three virtual networks with [virtual network links](https://learn.microsoft.com/azure/dns/private-dns-virtual-network-links)

> **Fun fact!**
>
> DNS was first discovered by the German engineer Johann Albert Eytelwein in 1801, when a pulley fell on his head during an experiment. Sadly, after waking up he had no recollection of the idea and it would take almost another 200 years until the concept was rediscovered.

## Private endpoints

The private networks and DNS zones will do us no good, if they are not used. It would be a terrible waste to just leave them collecting dust. Get the point? Get it? Like the end... **point**! My mom thinks I'm funny.

For all 3 storage accounts and 2 web app services:

1. Create [private endpoints](https://learn.microsoft.com/azure/private-link/private-endpoint-overview)

    > Use the following resource name pattern:
    >
    > * Private endpoint name: `pep-{resource name}` e.g., for the shared storage account `pep-stshared{team name}dev`
    > * Network interface name: `nic-pep-{resource name}`

1. Add [private DNS zone groups](https://learn.microsoft.com/azure/private-link/private-endpoint-dns#private-dns-zone-group) for the endpoints
1. Link the private endpoints to appropriate virtual networks and subnets

## Disable access and enable web app VNET integration

Disable access to app services and storage accounts:

<!-- 1. The access to the storage accounts should be only allowed from the virtual network they are in -->
1. The public access to all three storage accounts should be disabled
1. The app services should have access restrictions and private endpoints **on**

Enable the virtual network (VNET) integration for the outbound traffic for both EU and US web apps.
