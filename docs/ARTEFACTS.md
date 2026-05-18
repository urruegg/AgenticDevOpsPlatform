# Artefact Catalogue

| Field | Value |
|-------|-------|
| **Version** | 1.0.0 |
| **Date** | 2026-05-18 |
| **Author** | Urs Rüegg |
| **Status** | Draft |
| **Previous Version** | — (initial release) |

> **Single entry point** for all Agentic DevOps Platform documentation.
> Read this file first, then drill into the document relevant to your task.

## Table of Contents

1. [Solution-Level Documents](#solution-level-documents)
2. [Sub-Component Documents](#sub-component-documents-populated-as-components-are-added)
3. [Reading Order by Task](#reading-order-by-task)

## Solution-Level Documents

| Document | Purpose | Read before changing... |
|----------|---------|------------------------|
| [SOLUTION_OVERVIEW.md](SOLUTION_OVERVIEW.md) | End-to-end solution overview, use cases, governance, roadmap | Any cross-cutting initiative or onboarding |
| [PRD.md](PRD.md) | Product requirements: personas, user journeys, FR/NFR catalogue with stable IDs, traceability matrix | Any scope/feature/requirement change; ALWAYS read before writing user stories or PRs |
| [ARCHITECTURE.md](ARCHITECTURE.md) | System architecture, agent topology, integrations, hosting | Service boundaries, agent contracts, infra topology |
| [AI.md](AI.md) | Responsible AI guidelines, agent governance, model selection, prompt patterns | Agent prompts, model upgrades, RAI compliance |
| [SECURITY.md](SECURITY.md) | Zero Trust, identity, managed identity, auth, secrets, RBAC | Auth flows, Key Vault, RBAC, CORS |
| [DATA.md](DATA.md) | Agent memory, trace storage, Cosmos DB partitioning, retention | Data models, partition keys, retention |
| [INFRASTRUCTURE.md](INFRASTRUCTURE.md) | Azure resource inventory, Bicep modules, environments | Infra provisioning, environment config |
| [ALM_PLAN.md](ALM_PLAN.md) | CI/CD pipelines, OIDC federation, deployment strategy | Workflows, release process, rollback |
| [TEST.md](TEST.md) | Test strategy, coverage thresholds, eval harness | Test patterns, eval gates |
| [adr/](adr/) | Architecture Decision Records | Any cross-cutting change |
| [../sprints/](../sprints/) | Sprint plan and per-sprint deliverables for implementing the platform | Sprint planning, scope changes, delivery tracking |

## Sub-Component Documents *(populated as components are added)*

| Component | Folder | Status |
|-----------|--------|--------|
| Agents (orchestrator, spec parser, drift, PR review) | `agents/` | Planned |
| Tools / skill adapters | `tools/` | Planned |
| API / webhook host | `api/` | Planned |
| Infrastructure (Bicep) | `infra/` | Planned |
| Evaluations | `evals/` | Planned |

## Reading Order by Task

| If you are... | Read in this order |
|---------------|-------------------|
| **Onboarding to the project** | `SOLUTION_OVERVIEW.md` → `PRD.md` → `ARCHITECTURE.md` → `SECURITY.md` |
| **Adding or changing a feature** | `PRD.md` (find/add requirement IDs) → relevant sprint doc → `ARCHITECTURE.md` / `SECURITY.md` |
| **Adding an agent** | `AI.md` → `ARCHITECTURE.md` → `TEST.md` |
| **Adding an agent tool** | `SECURITY.md` → `ARCHITECTURE.md` → `TEST.md` |
| **Changing infrastructure** | `INFRASTRUCTURE.md` → `ALM_PLAN.md` → `SECURITY.md` |
| **Changing CI/CD** | `ALM_PLAN.md` → `SECURITY.md` |
| **Adding/changing data stores** | `DATA.md` → `SECURITY.md` |
| **Recording a cross-cutting decision** | `adr/` (use the template) |
| **Planning or delivering a sprint** | `../sprints/README.md` → `../sprints/SPRINT_PLAN.md` → relevant `sprint-NN-*.md` |
