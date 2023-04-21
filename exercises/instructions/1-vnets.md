# Virtual networks

Let's start simple. Your mission, should you accept it, is to create three virtual networks. These virtual networks will form a network boundary around the Azure resource assigned to them, allowing you to control all traffic to and from.

Each one should span 1024 IP addresses with first virtual network starting from IP `10.0.0.0`. Have the address spaces of all the virtual networks adjacent i.e, to be next to each other i.e., no empty space between.

The recommended order and names below:

1. `vnet-{team name}-dev-northeurope` in North Europe (starting from 10.0.0.0)
1. `vnet-{team name}-dev-westeurope` in West Europe
1. `vnet-{team name}-dev-eastus` in East US

If you have time left over, debate the existentialism of virtual networks. Are they real? Am I?
