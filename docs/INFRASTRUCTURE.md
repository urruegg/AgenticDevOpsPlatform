# Infrastructure

| Field | Value |
|-------|-------|
| **Version** | 2.0.0 |
| **Date** | 2026-05-18 |
| **Author** | Urs Rüegg |
| **Status** | Draft |
| **Previous Version** | 1.0.0 (planned Container Apps / Functions / Cosmos DB / Key Vault / App Insights as platform runtime infrastructure); 2.0.0 retires that scope per [ADR-0002](adr/0002-runtime-is-github-copilot-coding-agent.md). This platform has **no Azure runtime infrastructure of its own**. The Bicep layout below is the template library UC1 *produces* for the customer's landing zone. |

> **Related**: [ADR-0002](adr/0002-runtime-is-github-copilot-coding-agent.md),
> [ARCHITECTURE.md](ARCHITECTURE.md), [ALM_PLAN.md](ALM_PLAN.md),
> [SECURITY.md](SECURITY.md).

## Table of Contents

1. [Scope: Platform vs UC1 Outputs](#1-scope-platform-vs-uc1-outputs)
2. [Platform Infrastructure (none)](#2-platform-infrastructure-none)
3. [UC1 Output — Landing-Zone Template Library](#3-uc1-output--landing-zone-template-library)
4. [Customer Environments (UC1 Outputs)](#4-customer-environments-uc1-outputs)
5. [IaC Conventions](#5-iac-conventions)
6. [Identity & Access (target side)](#6-identity--access-target-side)
7. [Networking (UC1 output)](#7-networking-uc1-output)
8. [Cost Targets](#8-cost-targets)
9. [Open Questions](#9-open-questions)

## 1. Scope: Platform vs UC1 Outputs

Two distinct scopes live in this document:

- **Platform infrastructure** — what is needed to *run* the platform. Per
  [ADR-0002](adr/0002-runtime-is-github-copilot-coding-agent.md), this
  scope is empty: agents run inside GitHub Copilot coding agent on
  GitHub-managed compute, and the repo holds the agent definitions.
- **UC1 output infrastructure** — the Bicep template library the Spec
  Parser Agent assembles into a PR against a customer's ADO Repo. These
  templates target the customer's subscriptions; they are *not* the
  platform's hosting infrastructure.

Everything below §2 refers to UC1 outputs.

## 2. Platform Infrastructure (none)

- **No Container Apps / App Service / Functions** for the platform.
- **No Cosmos DB** for platform memory or traces (see [DATA.md](DATA.md)).
- **No Key Vault** for platform secrets (GitHub Actions secrets cover CI;
  MCP servers use federated credentials).
- **No Application Insights / Log Analytics** for the platform (run history
  is GitHub-native).
- **No private endpoints / VNet** owned by the platform.

The single durable platform asset is the **GitHub repository itself**.

Workflows in `.github/workflows/` may *touch* Azure (e.g., `iac-validate.yml`
runs `az deployment what-if` against a customer subscription on behalf of
UC1), but those calls authenticate via federated OIDC to a customer-side
service principal; no Azure resources are owned by this repo.

## 3. UC1 Output — Landing-Zone Template Library

The UC1 Spec Parser Agent assembles `.bicep` and `.bicepparam` files from
the template library under `infra/` into a PR against the customer's ADO
Repo. Sprint 2 introduces the first templates; subsequent sprints add
more as use cases require.

```
infra/                              # UC1 template library (this repo)
  main.bicep                        # Subscription/RG composition template
  main.parameters.<env>.json        # Example parameter sets (per customer env)
  modules/
    identity.bicep                  # User-assigned managed identities
    keyvault.bicep                  # Key Vault + RBAC (customer-owned)
    cosmosdb.bicep                  # Cosmos account, DB, containers, HPK (customer workload, if needed)
    observability.bicep             # Log Analytics + App Insights (customer-owned)
    containerapps.bicep             # Workload host (customer-owned)
    network.bicep                   # VNet, subnets, private endpoints (prod)
```

**Module conventions** for UC1 outputs:

- One module per resource type under `infra/modules/`.
- Compose from `infra/main.bicep`; never hard-code resource names.
- Parameterise environment (`dev` / `test` / `prod`) for the **customer's**
  landing zone.
- Mandatory tags on every resource: `env`, `owner`, `costCenter`, `workload`.
- Diagnostic settings → Log Analytics on every production resource.
- The agent must run `az deployment ... what-if` before any `create`; this
  is enforced by the per-agent prompt.
- Use **Azure Verified Modules (AVM)** where they exist and match
  requirements.

## 4. Customer Environments (UC1 Outputs)

The `dev` / `test` / `prod` triad applies to the **customer's** landing
zone, not to this repo. The agent's PR contains the parameter sets needed
to deploy each environment.

| Environment | Purpose | Resource Group Pattern (example) | Tags |
|-------------|---------|----------------------------------|------|
| `dev` | Customer engineering experimentation | `rg-<workload>-dev` | `env=dev` |
| `test` | Customer pre-prod validation | `rg-<workload>-test` | `env=test` |
| `prod` | Customer production | `rg-<workload>-prod` | `env=prod` |

The resource group naming, region, and SKUs are driven by the customer's
WorkIQ spec; the table above is illustrative only.

## 5. IaC Conventions

Applies to any `.bicep` committed under `infra/`:

- **Bicep** is the default. Terraform is allowed only when a verified
  module is unavailable in Bicep or a multi-cloud requirement applies
  (must be justified in an ADR).
- One module per resource type; composition in `main.bicep`.
- Parameterise environment; never hard-code names.
- Required tags on every resource: `env`, `owner`, `costCenter`, `workload`.
- Diagnostic settings on every production resource.
- `what-if` before any `create`; the per-agent prompt enforces this for
  UC1 deployments.
- Lint with `az bicep lint` and AVM checks; both enforced in `iac-validate.yml`.

## 6. Identity & Access (target side)

- **Customer-side Managed Identity** for service-to-service connections
  inside the UC1-deployed landing zone.
- **Federated Workload Identity** for the GitHub Actions / Azure DevOps
  pipelines that actually run `az deployment create` on the customer's
  behalf. No long-lived secrets.
- See [SECURITY.md](SECURITY.md) for the full identity model.

## 7. Networking (UC1 output)

Applies to the customer's landing zone when a UC1 spec calls for it:

- **Hub-spoke topology** in `prod`.
- **Private endpoints** for Key Vault, Cosmos DB, Storage.
- **Egress** via NSG / Azure Firewall.
- **Front Door / APIM** for any external surface (only when the spec
  requires it).

The platform itself has no networking footprint.

## 8. Cost Targets

Cost targets apply to the **customer's** UC1-deployed landing zone and
are driven by the spec. The platform's own running cost is essentially
zero (GitHub repo + GitHub Actions free-tier usage + any MCP server tier
the customer pays for separately).

| Environment (customer side) | Monthly target | Notes |
|------------------------------|----------------|-------|
| `dev` | Spec-driven | Auto-shutdown where possible |
| `test` | Spec-driven | Scale-to-zero off-hours |
| `prod` | Spec-driven | Reserved capacity once steady-state validated |

## 9. Open Questions

- Final shape of the AVM allow-list used by the UC1 Spec Parser Agent.
  Resolved in Sprint 2.

