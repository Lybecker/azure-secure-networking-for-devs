<!-- markdownlint-disable MD033 -->
# <strike>None</strike>Some shall pass
<!-- markdownlint-enable MD033 -->

> Ooh wee! The previous exercise sure was tedious. I don't blame you, if you didn't get all the way through. To catch up, run the script:
>
> ```ps1
> .\2-private-network.ps1 -TeamName <your team name>
> ```

Oops! Anybody got the key? Now, this is embarrassing; I think we just locked ourselves out of the entire system! Try it out by access the web apps or storage accounts.

Let's fix that!

## Virtual machine

1. Create [network security group (NSG)](https://learn.microsoft.com/azure/virtual-network/network-security-groups-overview)
    * Name: `nsg-jumpbox-{team name}-dev`
    * Location: North Europe
1. Add rule to the NSG to deny all inbound traffic.
1. Create a Windows desktop virtual machine with no public IP or public inbound ports. Assign the network security group to the virtual machine.
    * Name: `vm{team name}`
    * Location: North Europe

## Bastion

So, umm... we created a virtual machine we can't access. What was the point of that?!

The solution:

1. Create a subnet for Azure Bastion in the VNET in the shared location - the name and size need to be specific and you must figure out what they are
1. Create a public IP address
    * Name: `pip-bastion-{team name}-dev` (see what we're getting at?)
    * Location: North Europe
1. Create [Azure Bastion](https://learn.microsoft.com/azure/bastion/bastion-overview) resource using the newly created public IP address and add it to the virtual network
    * Name: `bas-{team name}-dev`
    * Location: North Europe

Login to the virtual machine using Azure Bastion and verify that your Private DNS Zone work, by running in a command prompt `nslookup app-<your team name>-dev-eu.azurewebsites.net`. You should see an IP from the private IP address space.

This exercise can only be completed by installing Solitaire and winning the game. Extra points for pro mode i.e., allowing only one time to go through the deck.
