# Previously on Networking

> *intro music plays* as our hero wanders in the wild:
>
> ```ps1
> .\5-firewall.ps1
> ```

## Network Security Group

1. Create [network security group (NSG)](https://learn.microsoft.com/azure/virtual-network/network-security-groups-overview) in **EU and US** locations.
2. Create [network security group rule (NSG)](https://learn.microsoft.com/azure/virtual-network/network-security-groups-overview#security-rules) to allow inbound SQL port.
3. Create a Linux desktop virtual machine, in both locations, with no public IP or public inbound ports. Assign the network security group to the virtual machine.

> Naming recommendations:
>
> * NSG: `nsg-{subnet-name}-{team name}-dev`
> * VM: `vm{team name}` (Linux VM resource names are [restrictred to maximum of 15 characters](https://learn.microsoft.com/azure/azure-resource-manager/management/resource-name-rules#microsoftcompute))

## Status check

```mermaid
graph
    subgraph rg-eu-["rg-{team name}-dev-eu"]
        subgraph vnet-eu["vnet-{team name}-dev-eu"]
            subgraph snet-database-eu["snet-{subnet name}-{team name}-dev-eu"]
                nic-database-eu("nic-{subnet}-{team name}-dev-eu")
                vm-eu("vm{team name}")
            end
        end

        nsg-subnet-eu("nsg-{subnet name}-{team name}-dev-eu")
        
        nic-database-eu-- attached to -->nsg-subnet-eu
        nic-database-eu-- attached to -->vm-eu

    end

    subgraph rg-us-["rg-{team name}-dev-us"]
        subgraph vnet-us["vnet-{team name}-dev-us"]
            subgraph snet-database-us["snet-{subnet name}-{team name}-dev-us"]
                nic-database-us("nic-{subnet}-{team name}-dev-us")
                vm-us("vm{team name}")
            end
        end

        nsg-subnet-us("nsg-{subnet name}-{team name}-dev-eu")
        
        nic-database-us-- attached to -->nsg-subnet-us
        nic-database-us-- attached to -->vm-us

    end

```

## Tips and tricks

* [Network traffic with network security group](https://learn.microsoft.com/en-gb/azure/virtual-network/tutorial-filter-network-traffic)

### Relevant Azure CLI commands

* [az network nsg create](https://learn.microsoft.com/cli/azure/network/nsg?view=azure-cli-latest#az-network-nsg-create())
* [az network nsg rule create](https://learn.microsoft.com/cli/azure/network/nsg/rule?view=azure-cli-latest#az-network-nsg-rule-create())
* [az network nic create](https://learn.microsoft.com/cli/azure/network/nic?view=azure-cli-latest#az-network-nic-create())
* [az vm image list](https://learn.microsoft.com/cli/azure/vm/image?view=azure-cli-latest#az-vm-image-list())
* [az vm create](https://learn.microsoft.com/cli/azure/vm?view=azure-cli-latest#az-vm-create())
