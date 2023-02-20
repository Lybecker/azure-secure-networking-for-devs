param jumpboxName string

param location string = resourceGroup().location

@minLength(1)
@maxLength(90)
param vnetResourceGroupName string

@minLength(2)
@maxLength(64)
param vnetName string

@minLength(1)
@maxLength(80)
param subnetName string

param adminUsername string

@secure()
param adminPassword string

var jumpboxVirtualMachineName = 'vm-${jumpboxName}'

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2021-05-01' existing  = {
  name: vnetName
  scope: resourceGroup(vnetResourceGroupName)
}

resource networkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2021-05-01' = {
  name: 'nsg-${jumpboxName}'
  location: location
}

resource jumpboxNic 'Microsoft.Network/networkInterfaces@2021-05-01' = {
  name: 'nic-${jumpboxName}'
  location: location

  properties: {
    ipConfigurations: [
      {
        name: 'internalIPConfig'

        properties: {
          subnet: {
            id: '${virtualNetwork.id}/subnets/${subnetName}'
          }

          privateIPAllocationMethod: 'Dynamic'
        }
      }
    ]

    networkSecurityGroup: {
      id: networkSecurityGroup.id

      properties: {
        securityRules: [
          {
            name: 'DenyAllInbound'

            properties: {
              description: 'Denies all inbound traffic'
              access: 'Deny'
              direction: 'Inbound'
              protocol: '*'
            }
          }
        ]
      }
    }
  }
}

resource jumpbox 'Microsoft.Compute/virtualMachines@2021-07-01' = {
  name: jumpboxVirtualMachineName
  location: location

  properties: {
    hardwareProfile: {
      vmSize: 'Standard_DS1_v2'
    }

    networkProfile: {
      networkInterfaces: [
        {
          id: jumpboxNic.id
        }
      ]
    }

    osProfile: {
      adminPassword: adminPassword
      adminUsername: adminUsername
      computerName: 'vm-jumpbox'
      windowsConfiguration: {}
    }

    storageProfile: {
      imageReference: {
        offer: 'windows-10'
        publisher: 'MicrosoftWindowsDesktop'
        sku: '20h2-pro-g2'
        version: 'latest'
      }

      osDisk: {
        createOption: 'FromImage'
        deleteOption: 'Delete'
      }
    }
  }
}
