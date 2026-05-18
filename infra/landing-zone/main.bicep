// UC1 output — landing-zone composition root.
//
// The spec-parser agent supplies parameters from a validated WorkIQ spec
// (see schemas/landing-zone-spec.schema.json). This module composes the
// resource-group-scoped resources for a single environment.
//
// Per ADR-0003 (Bicep as IaC) and AGENTS.md §4, deploy is gated by an
// explicit `approved-to-apply` comment from a human reviewer.

targetScope = 'resourceGroup'

@minLength(3)
@maxLength(24)
@description('Short, lowercase workload identifier; suffix for every resource name.')
param workloadName string

@allowed([
  'dev'
  'test'
  'stg'
  'prod'
])
@description('Target environment for this deployment.')
param environment string

@description('Azure region for resources in this resource group.')
param location string = resourceGroup().location

@description('VNet IPv4 CIDR. /16..../24.')
param vnetCidr string

@description('Subnets to provision in the VNet.')
param subnets array

@description('Required tags applied to every resource (env, owner, costCenter, workload).')
param tags object

var vnetName = 'vnet-${workloadName}-${environment}'

module network 'modules/network.bicep' = {
  name: 'network'
  params: {
    vnetName: vnetName
    location: location
    addressPrefix: vnetCidr
    subnets: subnets
    tags: tags
  }
}

output vnetId string = network.outputs.vnetId
output vnetName string = vnetName
output subnetNames array = network.outputs.subnetNames
