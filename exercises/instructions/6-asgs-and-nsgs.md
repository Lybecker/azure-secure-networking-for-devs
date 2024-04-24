# ASGs, NSGs, and other various types of Stargåtes

> In case you're still feelin' the burn, run the script:
>
> ```ps1
> .\5-firewall.ps1
> ```

## Application and network security groups

> [!CAUTION]
> Contrary to what most people are accustomed to, "SG" here does not mean "Stargate", but "security group". Sorry for the misleading title.

[**Application security groups (ASGs)**](https://learn.microsoft.com/azure/virtual-network/application-security-groups) enable you to configure network security as a natural extension of an application's structure, allowing you to group virtual machines and **private endpoints** and define network security policies based on those groups.

You can use an Azure [**network security group (NSG)**](https://learn.microsoft.com/azure/virtual-network/network-security-groups-overview) to filter network traffic between Azure resources in an Azure virtual network. A network security group contains security rules that allow or deny inbound network traffic to, or outbound network traffic from, several types of Azure resources. For each rule, you can specify source and destination, port, and protocol. NSGs can be associated with subnets and network interfaces (NICs).

The goal of this task sounds simple: For both EU and US storage accounts: Allow access only from the app services in the same region e.g., `app-<your team name>-dev-eu` should be able to access `st<your team name>deveu`, but inbound traffic from everything else should be blocked.

To start off with:

1. Create a network security group in EU resource group and location
1. Create an application security group for storage account in EU resource group and location, and associated it with the private endpoint of the storage account
1. Create a new [network security group rule (NSG)](https://learn.microsoft.com/azure/virtual-network/network-security-groups-overview#security-rules) to deny all traffic to the storage account using the newly created ASG
1. Verify that the app service no longer can access the storage account using the `list_blobs` endpoint
1. Create a new security group rule to allow access only from the app service in the region
1. Verify that the app service can again access the storage account
1. Rinse and repeat for the US region

> Naming recommendations:
>
> * NSG: `nsg-{default subnet-name}`
> * ASG: `asg-storage-{team name}-dev-{eu|us}`

## Quiz

Why won't the following approaches work in network security group rules in our case?

1. Storage service tags
1. ASGs associated with app service private endpoints

## Status check

You did that already, didn't you, you silly-billy!

### Relevant Azure CLI commands

* [az network asg create](https://learn.microsoft.com/cli/azure/network/asg?view=azure-cli-latest#az-network-asg-create)
* [az network private-endpoint asg add](https://learn.microsoft.com/cli/azure/network/private-endpoint/asg?view=azure-cli-latest#az-network-private-endpoint-asg-add)
* [az network nsg create](https://learn.microsoft.com/cli/azure/network/nsg?view=azure-cli-latest#az-network-nsg-create)
* [az network nsg rule create](https://learn.microsoft.com/cli/azure/network/nsg/rule?view=azure-cli-latest#az-network-nsg-rule-create)

## Back to the overview

[Azure Secure Networking for Developers - start page](/README.md)
