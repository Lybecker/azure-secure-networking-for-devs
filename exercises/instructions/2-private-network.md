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

1. In the "shared" virtual network - the one by default in Sweden (heja Sverige!) - create a subnet for shared resources: `snet-shared-{team name}-dev-{location}`, span of 64 (or 64 - 5 = 59) IP addresses should be plenty for our needs
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

How about those resources - sure keep piling up, eh? Notice something funny regarding the app services with respect to subnets?

```mermaid
graph
    subgraph rg-hub["rg-hub-{team name}-dev"]
        subgraph vnet-hub["vnet-{team name}-dev-{hub location}"]
            subgraph snet-shared-hub["snet-shared-{team name}-dev-{hub location}"]
                st-hub("sthub{team name}dev")
                nic-pep-st-hub("nic-pep-sthub{team name}dev")
                pep-st-hub("pep-sthub{team name}dev")
            end
        end

        priv-dns-zone-blobs{"privatelink.blob.core.windows.net"}
        priv-dns-zone-sites{"privatelink.azurewebsites.net"}

        st-hub---pep-st-hub
        nic-pep-st-hub-- attached to -->pep-st-hub
    end

    subgraph rg-eu["rg-{team name}-dev-eu"]
        asp-eu("asp-{team name}-dev-eu")

        subgraph vnet-eu["vnet-{team name}-dev-{EU location}"]
            subgraph snet-apps-eu["snet-apps-{team name}-dev-{EU location}"]
                app-eu("app-{team name}-dev-eu")
            end

            subgraph snet-shared-eu["snet-shared-{team name}-dev-{EU location}"]
                st-eu("st{team name}deveu")
                nic-pep-st-eu("nic-pep-st{team name}deveu")
                pep-st-eu("pep-st{team name}deveu")
                nic-pep-app-eu("nic-app-{team name}-dev-eu")
                pep-app-eu("pep-app-{team name}-dev-eu")
            end
        end

        asp-eu---app-eu
        app-eu-- Storage Blob Data Contributor -->st-hub
        app-eu-- Storage Blob Data Contributor -->st-eu

        st-eu---pep-st-eu
        nic-pep-st-eu-- attached to -->pep-st-eu
        app-eu---pep-app-eu
        nic-pep-app-eu-- attached to -->pep-app-eu
    end

    subgraph rg-us["rg-{team name}-dev-us"]
        asp-us("asp-{team name}-dev-us")

        subgraph vnet-us["vnet-{team name}-dev-{US location}"]
            subgraph snet-apps-us["snet-apps-{team name}-dev-{US location}"]
                app-us("app-{team name}-dev-us")
            end

            subgraph snet-shared-us["snet-shared-{team name}-dev-{US location}"]
                st-us("st{team name}devus")
                nic-pep-st-us("nic-pep-st{team name}devus")
                pep-st-us("pep-st{team name}devus")
                nic-pep-app-us("nic-app-{team name}-dev-us")
                pep-app-us("pep-app-{team name}-dev-us")
            end
        end

        asp-us---app-us
        app-us-- Storage Blob Data Contributor -->st-hub
        app-us-- Storage Blob Data Contributor -->st-us

        st-us---pep-st-us
        nic-pep-st-us-- attached to -->pep-st-us
        app-us---pep-app-us
        nic-pep-app-us-- attached to -->pep-app-us
    end

    vnet-hub-- linked ---priv-dns-zone-blobs
    vnet-hub-- linked ---priv-dns-zone-sites
    vnet-eu-- linked ---priv-dns-zone-blobs
    vnet-eu-- linked ---priv-dns-zone-sites
    vnet-us-- linked ---priv-dns-zone-blobs
    vnet-us-- linked ---priv-dns-zone-sites
    pep-st-hub---priv-dns-zone-blobs
    pep-st-eu---priv-dns-zone-blobs
    pep-st-us---priv-dns-zone-blobs
    pep-app-eu---priv-dns-zone-sites
    pep-app-us---priv-dns-zone-sites
```

## Tips and tricks

### Learning resources

* [Add, change, or delete a virtual network subnet](https://learn.microsoft.com/azure/virtual-network/virtual-network-manage-subnet?tabs=azure-portal)
* [What is a private Azure DNS zone?](https://learn.microsoft.com/azure/dns/private-dns-privatednszone)
* [What is a private endpoint?](https://learn.microsoft.com/azure/private-link/private-endpoint-overview)

### Relevant Azure CLI commands

* [az-network-vnet-subnet-create](https://learn.microsoft.com/cli/azure/network/vnet/subnet?view=azure-cli-latest#az-network-vnet-subnet-create())
* [az network private-dns zone create](https://learn.microsoft.com/cli/azure/network/private-dns/zone?view=azure-cli-latest#az-network-private-dns-zone-create())
* [az network private-dns link vnet create](https://learn.microsoft.com/en-us/cli/azure/network/private-dns/link/vnet?view=azure-cli-latest#az-network-private-dns-link-vnet-create())
* [az network private-endpoint create](https://learn.microsoft.com/cli/azure/network/private-endpoint?view=azure-cli-latest#az-network-private-endpoint-create())
* [az network private-endpoint dns-zone-group add](https://learn.microsoft.com/en-us/cli/azure/network/private-endpoint/dns-zone-group?view=azure-cli-latest#az-network-private-endpoint-dns-zone-group-add())
* [az resource update](https://learn.microsoft.com/cli/azure/resource?view=azure-cli-latest#az-resource-update())
* [az webapp vnet-integration add](https://learn.microsoft.com/cli/azure/webapp/vnet-integration?view=azure-cli-latest#az-webapp-vnet-integration-add())
