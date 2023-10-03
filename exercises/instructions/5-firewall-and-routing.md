# Extra credit: Shields up, red alert!

> Gotta have them networks peered so if they ain't, go do it:
>
> ```ps1
> .\4-vnet-peerings.ps1
> ```

## Firewall

Set up [Azure Firewall](https://learn.microsoft.com/azure/firewall/overview) - not the basic SKU - in the virtual network in the **hub location**.

## Routing

Finally:

1. Add a [route table](https://learn.microsoft.com/azure/virtual-network/manage-route-table) and direct next hop traffic from VM to Azure Firewall
1. Block all sites except GitHub

## Status check

```mermaid
graph
    subgraph rg-hub["rg-hub-{team name}-dev"]
        subgraph vnet-hub["vnet-{team name}-dev-{hub location}"]
            subgraph snet-shared-hub["snet-shared-{team name}-dev-{hub location}"]
                st-hub("sthub{team name}dev")
                nic-pep-st-hub("nic-pep-sthub{team name}dev")
                pep-st-hub("pep-sthub{team name}dev")
                nic-jumpbox("nic-jumpbox-{team name}-dev")
                vm("vm{team name}")
            end

            subgraph snet-bas["AzureBastionSubnet"]
                bas("bas-{team name}-dev")
            end

            subgraph snet-afw["AzureFirewallSubnet"]
                afw("afw-{team name}-dev-{hub location}")
            end
        end

        nsg-jumpbox("nsg-jumpbox-{team name}-dev")
        pip-bas("pip-bastion-{team name}-dev")

        pip-afw("pip-firewall-{team name}-dev-{hub location}")

        priv-dns-zone-blobs{"privatelink.blob.core.windows.net"}
        priv-dns-zone-sites{"privatelink.azurewebsites.net"}

        st-hub---pep-st-hub
        nic-pep-st-hub-- attached to -->pep-st-hub

        nic-jumpbox-- attached to -->nsg-jumpbox
        nic-jumpbox-- attached to -->vm
        pip-bas-- associated to -->bas

        pip-afw-- associated to -->afw
    end

    vnet-hub-- linked ---priv-dns-zone-blobs
    vnet-hub-- linked ---priv-dns-zone-sites
    pep-st-hub---priv-dns-zone-blobs
```
