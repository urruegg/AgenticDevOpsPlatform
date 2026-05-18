// UC1 output — network module.
//
// Provisions a single VNet with the supplied subnets. Diagnostics, NSGs, and
// private endpoints are layered in subsequent sprints (S3+).

@description('VNet name.')
param vnetName string

@description('Region.')
param location string

@description('VNet address prefix (e.g., 10.40.0.0/16).')
param addressPrefix string

@description('Subnets array of { name: string, cidr: string, delegations: string[] }.')
param subnets array

@description('Required tags.')
param tags object

resource vnet 'Microsoft.Network/virtualNetworks@2024-01-01' = {
  name: vnetName
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        addressPrefix
      ]
    }
  }
}

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2024-01-01' = [for s in subnets: {
  parent: vnet
  name: s.name
  properties: {
    addressPrefix: s.cidr
    delegations: [for d in (s.?delegations ?? []): {
      name: replace(d, '/', '-')
      properties: {
        serviceName: d
      }
    }]
  }
}]

output vnetId string = vnet.id
output subnetNames array = [for s in subnets: s.name]
