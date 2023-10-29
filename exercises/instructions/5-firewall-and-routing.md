# Extra credit: Shields up, red alert!

> Gotta have them networks peered so if they ain't, go do it:
>
> ```ps1
> .\4-vnet-peerings.ps1
> ```

You secured a lot of stuff in the previous exercises, but there's still a lot of work to do. Let's get to it!

We would like restrict data exfiltration of data. That means controlling the traffic between the virtual network and the internet. We'll do that by setting up a firewall to route all egress (outgoing) traffic through.

## Firewall

We have already created an [Azure Firewall](https://learn.microsoft.com/azure/firewall/overview) for you in the hub virtual network.

Azure Firewall and Azure Bastion are both shared resources, so they are placed in the hub virtual network. This means that they can be used by all virtual networks in the hub.

> Cost is another reason to not create many instances of Azure Firewall and Azure Bastion. They are both billed for allocation per hour and for data traffic processed. Unlike e.g. Azure Key Vault that only is billed per usage.

The Azure Firewall requires a subnet like Azure Bastion named `AzureFirewallSubnet` and a public IP. The public IP will the source IP of all outgoing traffic from the virtual network on the public Internet.

By default the Firewall allows no traffic. You need to create rules to allow traffic. There are tree types of rules:

- NAT rules - allows you to share network services with external networks. E.g. you can use a single public IP address to allow external clients to access multiple internal servers.
- Network rules - non-HTTP/S traffic that will be allowed to flow through the firewall must have a network rule.
- Application rules - HTTP/HTTPS traffic at Layer-7 network traffic filtering.


## Routing

The firewall is not used yet, so route all Internet the traffic through it.

1. Add a [route table](https://learn.microsoft.com/azure/virtual-network/manage-route-table) `rt-{teamname}-dev`, assign it to each subnet and route like this:
    - Destination: 0.0.0.0/0 (Internet)
    - Next hop type: Virtual appliance
    - Next hop address: Private IP of firewall
1. Create firewall rule(s) to block all sites except GitHub.com

## Status check

RDP into the jumpbox and verify that the only site you can visit is GitHub.com.

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

## Tips and tricks

### Learning resources

* [What is Azure Firewall?](https://learn.microsoft.com/azure/firewall/overview)

### Relevant Azure CLI commands

* [az network firewall create](https://learn.microsoft.com/cli/azure/network/firewall?view=azure-cli-latest#az-network-firewall-create(azure-firewall))
* [az network firewall ip-config create](https://learn.microsoft.com/cli/azure/network/firewall/ip-config?view=azure-cli-latest#az-network-firewall-ip-config-create(azure-firewall))
* [az network firewall update](https://learn.microsoft.com/cli/azure/network/firewall?view=azure-cli-latest#az-network-firewall-update(azure-firewall))
