param location string = resourceGroup().location
param adminUsername string
@secure()
param adminPassword string
param virtualNetworkName string
param subnetName string

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2020-11-01' existing = {
  name: virtualNetworkName
}

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2020-11-01' existing = {
  name: subnetName
  parent: virtualNetwork
}

resource nic 'Microsoft.Network/networkInterfaces@2022-05-01' = {
  name: 'nicvm'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: subnet.id
          }
        }
      }
    ]
  }
}

resource virtualMachine 'Microsoft.Compute/virtualMachines@2020-12-01' = {
  name: 'test-vm'
  location: location
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_D2s_v3'
    }
    storageProfile: {
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Standard_LRS'
        }
      }
      imageReference: {
        publisher: 'Canonical'
        offer: '0001-com-ubuntu-server-jammy'
        sku: '22_04-lts-gen2'
        version: 'latest'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
        }
      ]
    }
    osProfile: {
      adminPassword: adminPassword
      adminUsername: adminUsername
      computerName: 'test-vm'
    }
  }
}
