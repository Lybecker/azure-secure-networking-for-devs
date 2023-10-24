$location = "swedencentral"
$resourceGroup = "rg-corpwebsite-dev-${location}"

Write-Output "Creating resource group ${ResourceGroup}"
az group create `
    --name $resourceGroup  `
    --location $location

Write-Output "Creating virtual network vnet-corpwebsite-dev-${location}"
az network vnet create `
    --name vnet-corpwebsite-dev-${location} `
    --resource-group $resourceGroup `
    --location $location `
    --address-prefix 10.0.0.0/16 `
    --subnet-name snet-web-dev-${location} `
    --subnet-prefix 10.0.0.0/24 `

az network vnet subnet update `
    --name snet-web-dev-${location} `
    --resource-group $resourceGroup `
    --vnet-name vnet-corpwebsite-dev-${location} `
    --disable-private-endpoint-network-policies false `
    --disable-private-link-service-network-policies false

az network vnet subnet create `
    --name snet-db-dev-${location} `
    --vnet-name vnet-corpwebsite-dev-${location} `
    --resource-group $resourceGroup `
    --address-prefix 10.0.1.0/24 `
    --disable-private-endpoint-network-policies false `
    --disable-private-link-service-network-policies false

Write-Output "Creating virtual network vnet-hub-dev-${location}"
az network vnet create `
    --name vnet-hub-dev-${location} `
    --resource-group $resourceGroup `
    --location $location `
    --address-prefix 10.1.0.0/16 `
    --subnet-name snet-hub-dev-${location} `
    --subnet-prefix 10.1.0.0/24

Write-Output "Peering vnet-corpwebsite-dev-${location} with vnet-hub-dev-${location}"
az network vnet peering create `
    --name peer-corpwebsite-hub `
    --resource-group $resourceGroup `
    --vnet-name vnet-corpwebsite-dev-${location} `
    --remote-vnet vnet-hub-dev-${location} `
    --allow-vnet-access

az network vnet peering create `
    --name peer-hub-corpwebsite `
    --resource-group $resourceGroup `
    --vnet-name vnet-hub-dev-${location} `
    --remote-vnet vnet-corpwebsite-dev-${location} `
    --allow-vnet-access

Write-Output "Creating Bastion"
az network vnet subnet create `
    --name AzureBastionSubnet `
    --resource-group $resourceGroup `
    --vnet-name vnet-hub-dev-${location} `
    --address-prefix 10.1.1.0/26 `
    --disable-private-endpoint-network-policies false `
    --disable-private-link-service-network-policies false

az network public-ip create `
    --resource-group $resourceGroup `
    --name pip-bastion-dev-${location} `
    --sku Standard `
    --location $location

az network bastion create `
    --name bas-hub-dev-${location} `
    --public-ip-address pip-bastion-dev-${location} `
    --resource-group $resourceGroup `
    --vnet-name vnet-hub-dev-${location} `
    --location $location `
    --sku Basic

Write-Output "Creating Firewall"
az network vnet subnet create `
    --name AzureFirewallSubnet `
    --resource-group $resourceGroup `
    --vnet-name vnet-hub-dev-${location} `
    --address-prefix 10.1.1.64/26 `
    --disable-private-endpoint-network-policies true `
    --disable-private-link-service-network-policies true

az network firewall create `
    --name fw-hub-dev-${location} `
    --resource-group $resourceGroup `
    --location $location

az network public-ip create `
    --resource-group $resourceGroup `
    --name pip-fw-dev-${location} `
    --sku Standard `
    --location $location

az network firewall ip-config create `
    --firewall-name fw-hub-dev-${location} `
    --name config-fw-hub-dev-${location} `
    --public-ip-address pip-fw-dev-${location} `
    --resource-group $resourceGroup `
    --vnet-name vnet-hub-dev-${location}

az network firewall update `
    --name fw-hub-dev-${location} `
    --resource-group $resourceGroup

az network firewall network-rule create `
    --collection-name net-base-col `
    --destination-addresses 209.244.0.3 209.244.0.4 `
    --destination-ports 53 `
    --firewall-name fw-hub-dev-${location} `
    --name Allow-DNS `
    --protocols UDP `
    --resource-group $resourceGroup `
    --priority 200 `
    --source-addresses * `
    --action Allow

Write-Output "Creating (managed SQL) database"
az sql server create `
    --name sql-db-dev-${location} `
    --resource-group $resourceGroup `
    --location $location `
    --admin-user sqladmin `
    --admin-password "LifeIsComplexSoShouldYourP@asswordBerb46w35b"

Write-Output "Creating private endpoint for database"
$id=$(az sql server list --resource-group $resourceGroup --query '[].[id]' --output tsv)

az network private-endpoint create `
    --name pep-sql-corpwebsite `
    --resource-group $resourceGroup `
    --vnet-name vnet-corpwebsite-dev-${location} `
    --subnet snet-db-dev-${location} `
    --private-connection-resource-id ${id} `
    --group-ids sqlServer `
    --connection-name pl-sql-corpwebsite

Write-Output "Configuring private DNS zone for database"
az network private-dns zone create `
    --resource-group $resourceGroup `
    --name "privatelink.database.windows.net"

az network private-dns link vnet create `
    --resource-group $resourceGroup `
    --zone-name "privatelink.database.windows.net" `
    --name dnsl-sql `
    --virtual-network vnet-corpwebsite-dev-${location} `
    --registration-enabled false

az network private-endpoint dns-zone-group create `
    --resource-group $resourceGroup `
    --endpoint-name pep-sql-corpwebsite `
    --name zone-sql `
    --private-dns-zone "privatelink.database.windows.net" `
    --zone-name sql

Write-Output "Creating VM to act as a web server"
az vm create `
    --name vm-web-dev `
    --resource-group $resourceGroup `
    --image Ubuntu2204 `
    --size Standard_B2s `
    --vnet-name vnet-corpwebsite-dev-${location} `
    --subnet snet-web-dev-${location} `
    --admin-username azureuser `
    --public-ip-address "" `
    --generate-ssh-keys