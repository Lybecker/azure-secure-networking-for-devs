# Create a vnet with a subnet
az network vnet create --name MyVnet --resource-group MyResourceGroup --location eastus --address-prefix 10.0.0.0/16 --subnet-name MySubnet --subnet-prefix 10.0.1.0/24

# Create an NSG
az network nsg create --name MyNSG --resource-group MyResourceGroup --location eastus

# Create NSG rules for web traffic
az network nsg rule create --name AllowWebTraffic --nsg-name MyNSG --priority 100 --resource-group MyResourceGroup --access Allow --direction Inbound --protocol Tcp --destination-port-range 80

# Create NSG rules for database traffic
az network nsg rule create --name AllowDBTraffic --nsg-name MyNSG --priority 200 --resource-group MyResourceGroup --access Allow --direction Inbound --protocol Tcp --destination-port-range 1433

# Create an ASG for web servers
az network asg create --name WebServerASG --resource-group MyResourceGroup --location eastus

# Add web servers to the ASG
az network asg member add --asg-name WebServerASG --member-name WebServer1 --resource-id /subscriptions/{subscription-id}/resourceGroups/MyResourceGroup/providers/Microsoft.Compute/virtualMachines/WebServer1

# Apply the ASG to the NSG rule
az network nsg rule update --name AllowWebTraffic --nsg-name MyNSG --resource-group MyResourceGroup --access Allow --direction Inbound --priority 100 --source-asg WebServerASG

# Apply all access except to github.com 
az network nsg rule create --name AllowOutbound --nsg-name MyNSG --priority 300 --resource-group MyResourceGroup --access Allow --direction Outbound --protocol * --destination-address-prefix !github.com

# Associate the NSG with the subnet
az network vnet subnet update --name MySubnet --vnet-name MyVnet --resource-group MyResourceGroup --network-security-group MyNSG
