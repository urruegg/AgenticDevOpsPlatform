# Infrastructure

| Field | Value |
|-------|-------|
| **Version** | 1.0 |
| **Date** | 2026-05-18 |
| **Author** | Urs Rüegg |
| **Status** | Draft |
| **Previous Version** | — (initial release) |

> **Related**: [ARCHITECTURE.md](ARCHITECTURE.md), [ALM_PLAN.md](ALM_PLAN.md),
> [SECURITY.md](SECURITY.md).

## Table of Contents

1. [Environments](#1-environments)
2. [Resource Inventory (planned)](#2-resource-inventory-planned)
3. [Bicep Module Layout (planned)](#3-bicep-module-layout-planned)
4. [IaC Conventions](#4-iac-conventions)
5. [Identity & Access](#5-identity--access)
6. [Networking](#6-networking)
7. [Cost Targets](#7-cost-targets)
8. [Open Questions](#8-open-questions)

## 1. Environments

| Environment | Purpose | Resource Group Pattern | Tags |
|-------------|---------|------------------------|------|
| `dev` | Engineering experimentation | `rg-agenticdevops-dev` | `env=dev` |
| `test` | Pre-prod validation, eval runs | `rg-agenticdevops-test` | `env=test` |
| `prod` | Production / pilot BU | `rg-agenticdevops-prod` | `env=prod` |

Required tags on every resource: `env`, `owner`, `costCenter`, `workload`.

## 2. Resource Inventory (planned)

| Resource | Purpose | SKU (initial) |
|----------|---------|---------------|
| Azure Container Apps / App Service / Functions | Agent runtime hosts | TBD |
| Azure Cosmos DB (NoSQL) | Agent traces, sessions, drift reports | Serverless or autoscale |
| Azure Key Vault | Secrets for pipelines & runtime | Standard, RBAC mode |
| Application Insights | Agent telemetry | Workspace-based |
| Log Analytics Workspace | Central log retention | Pay-as-you-go |
| Storage Account | Artefacts, large traces (if needed) | Standard ZRS |
| Managed Identity (per agent) | Service identity for autonomous agents | User-assigned |
| Private Endpoints | KV / Cosmos / Storage (prod) | — |

## 3. Bicep Module Layout (planned)

```
infra/
  main.bicep                       # Subscription/RG composition
  main.parameters.dev.json
  main.parameters.test.json
  main.parameters.prod.json
  modules/
    identity.bicep                 # User-assigned managed identities
    keyvault.bicep                 # Key Vault + access policies
    cosmosdb.bicep                 # Cosmos account, DB, containers, HPK
    observability.bicep            # Log Analytics + App Insights
    containerapps.bicep            # Agent runtime hosts
    network.bicep                  # VNet, subnets, private endpoints (prod)
```

## 4. IaC Conventions
- **One module per resource type** under `infra/modules/`.
- **Compose from `infra/main.bicep`**; never hard-code resource names.
- **Parameterise environment** (`dev` / `test` / `prod`).
- **Tags on every resource** (mandatory): `env`, `owner`, `costCenter`, `workload`.
- **Diagnostic settings → Log Analytics** for every production resource.
- **Run `what-if`** before `az deployment ... create`.
- Use **Azure Verified Modules (AVM)** where they exist and match requirements.

## 5. Identity & Access
- **Managed Identity** for all service-to-service connections (no connection
  strings).
- See [SECURITY.md](SECURITY.md) §2 for RBAC tables.

## 6. Networking
- **Hub-spoke topology** in production (TBD).
- **Private endpoints** for Key Vault, Cosmos DB, Storage.
- **Egress** via NSG / Azure Firewall.
- **Front Door / APIM** for any external surface (TBD).

## 7. Cost Targets
| Environment | Monthly target | Notes |
|-------------|----------------|-------|
| dev | TBD | Auto-shutdown where possible |
| test | TBD | Scale-to-zero for off-hours |
| prod | TBD | Reserve capacity once steady-state validated |

## 8. Open Questions
- TBD
