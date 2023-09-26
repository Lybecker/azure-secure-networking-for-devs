# Some privacy, please!

> *(With trailer man sound) Previously on Azure secure networking exercise...*
>
> In case you need to catch up, run the script to get to where we need to be now:
>
> ```ps1
> .\1-vnets.ps1
> ```

## Subnets

Our virtual networks sure feel empty and sad. Let's cheer them up by giving them subnets!

1. In the "shared" virtual network - the one by default in Sweden (heja Sverige!) - create a subnet for shared resources: `snet-shared-{team name}-dev-{location}`, span of 64 IP addresses should be plenty for our needs
1. In the both two other virtual networks, create:
    1. `snet-shared-{team name}-dev-{location}` with the range of 128 addresses
    1. `snet-apps-{team name}-dev-{location}` with the range of 128 addresses
        * Delegate this subnet for `Microsoft.Web/serverFarms`

> The `shared` subnet is for any kind of Azure resources. The `apps` subnet is delegated to Azure web apps, meaning you cannot use it for anything else.

## Private DNS zones

Now, on to some D-N-S-ing (if that's not a word, it darn well should be).

1. Create two [private DNS zones](https://learn.microsoft.com/azure/dns/private-dns-privatednszone) for:
    1. Web apps ("`privatelink.azurewebsites.net`")
    1. Blob storages ("`privatelink.blob.core.windows.net`")
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
    > * Private endpoint name: `pep-{resource name}` e.g., for the hub storage account `pep-sthub{team name}dev`
    > * Network interface name: `nic-pep-{resource name}`

1. Add [private DNS zone groups](https://learn.microsoft.com/azure/private-link/private-endpoint-dns#private-dns-zone-group) for the endpoints
1. Link the private endpoints to appropriate virtual networks and subnets

> Azure web apps are a little bit special. They have private endpoints and VNET integration. Don't worry, you will figure it out!

## Disable access and enable web app VNET integration

Disable access to app services and storage accounts:

<!-- 1. The access to the storage accounts should be only allowed from the virtual network they are in -->
1. The public access to all three storage accounts should be disabled
1. The app services should have access restrictions and private endpoints **on**

Enable the virtual network (VNET) integration for the outbound traffic for both EU and US web apps.

Launch any of the two web apps (e.g., `https://app-<your team name>-dev-eu.azurewebsites.net/`) in your browser. You should now be greeted with not so friendly 403 message.

## Status check

TODO: Where are we now?
