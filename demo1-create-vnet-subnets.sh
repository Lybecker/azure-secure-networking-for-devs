# Expect a resource group named Networking

# Create a VNET with 65K addresses
az network vnet create --resource-group rg-networking --name vnet-demo --address-prefix 10.1.0.0/16

# Create a Subnet with 256(251) addresses from the VNET (can create 256 subnets of same size)
az network vnet subnet create --resource-group rg-networking --name snet-0 --vnet-name vnet-demo --address-prefixes 10.1.0.0/24

az network vnet subnet create --resource-group rg-networking --name snet-1 --vnet-name vnet-demo --address-prefixes 10.1.1.0/24
