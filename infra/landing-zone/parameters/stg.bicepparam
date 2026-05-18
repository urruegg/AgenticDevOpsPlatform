using '../main.bicep'

// Sample parameter file derived from samples/landing-zone-spec.json.
// The spec-parser agent emits parameter files like this from the validated
// WorkIQ spec; this checked-in copy is the byte-identical reference for the
// `happy-path` golden-task fixture (FR-UC1-005 deterministic generation).

param workloadName = 'contoso-payments'
param environment = 'stg'
param vnetCidr = '10.40.0.0/16'
param subnets = [
  {
    name: 'snet-app'
    cidr: '10.40.1.0/24'
    delegations: []
  }
  {
    name: 'snet-data'
    cidr: '10.40.2.0/24'
    delegations: []
  }
  {
    name: 'snet-pe'
    cidr: '10.40.3.0/24'
    delegations: []
  }
]
param tags = {
  env: 'stg'
  owner: 'platform-team@contoso.example'
  costCenter: 'CC-PAY-001'
  workload: 'contoso-payments'
}
