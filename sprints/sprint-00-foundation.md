# Sprint 0 — Foundation & Tooling

| Field | Value |
|-------|-------|
| **Version** | 1.0 |
| **Date** | 2026-05-18 |
| **Author** | Urs Rüegg |
| **Status** | Draft |
| **Previous Version** | — (initial release) |

> **Window**: 2026-05-18 → 2026-05-22 (1 week bootstrap)
> **Theme**: Bootstrap the repository, infrastructure, identity, and CI/CD foundations
> that every later sprint depends on.

---

## Table of Contents

1. [Goal & Outcomes](#1-goal--outcomes)
2. [Use Cases Addressed](#2-use-cases-addressed)
3. [Scope](#3-scope)
4. [User Stories & Acceptance Criteria](#4-user-stories--acceptance-criteria)
5. [Deliverables](#5-deliverables)
6. [Dependencies](#6-dependencies)
7. [Risks & Mitigations](#7-risks--mitigations)
8. [Exit Criteria](#8-exit-criteria)
9. [Demo Script](#9-demo-script)
10. [Related Documents](#10-related-documents)

---

## 1. Goal & Outcomes

Stand up the repository and Azure infrastructure scaffolding so the team can
start building agents in Sprint 1 against a production-shaped environment.

By the end of the sprint:

- `infra/main.bicep` provisions a `dev` resource group with Key Vault, Cosmos DB,
  Log Analytics, and Application Insights.
- GitHub Actions deploys to Azure via OIDC federation (no long-lived secrets).
- Entra app registrations and a placeholder Agent ID exist for the orchestrator.
- Python project skeleton (`agents/`, `tools/`, `api/`, `tests/`, `evals/`) with
  lint/format/test wired into CI.

---

## 2. Use Cases Addressed

- **None directly** — this is the platform foundation that all three use cases
  depend on.

---

## 3. Scope

### In Scope
- Bicep modules: `identity`, `keyvault`, `cosmos`, `loganalytics`, `appinsights`, `tags`.
- `azure.yaml` (azd) for `dev` environment.
- GitHub Actions workflows: `ci.yml`, `iac-validate.yml`, `deploy-dev.yml`.
- OIDC federation between GitHub and Azure (workload-identity federation).
- Entra: app registration for orchestrator agent + service principal with placeholder roles.
- Python project: `pyproject.toml` (Python 3.11+), `ruff`, `black`, `pytest`, `pre-commit`.
- Repo conventions: PR template, issue templates, CODEOWNERS.
- ADRs: `0002-bicep-as-iac.md`, `0003-cosmos-nosql-for-traces.md`, `0004-oidc-federation.md`.

### Out of Scope
- Any agent logic.
- Private endpoints (deferred to Sprint 6).
- Production (`prod`) environment (deferred).
- WorkIQ / ADO MCP setup (Sprint 1).

---

## 4. User Stories & Acceptance Criteria

### S0-1 — Repo scaffold
**As a** developer
**I want** a Python project with lint/format/test pre-wired
**so that** all future code lands with quality gates from day one.

**Acceptance**:
- [ ] `pip install -e .[dev]` succeeds on a clean clone.
- [ ] `pytest`, `ruff check .`, `black --check .` all pass.
- [ ] Pre-commit runs lint + tests on staged Python files.

### S0-2 — Azure infra skeleton
**As a** platform engineer
**I want** a Bicep template that provisions Key Vault, Cosmos DB, Log Analytics, App Insights
**so that** agents in later sprints have somewhere to store secrets and traces.

**Acceptance**:
- [ ] `az bicep build --file infra/main.bicep` succeeds.
- [ ] `az deployment group what-if -g rg-agentic-devops-dev -f infra/main.bicep` reports zero unintended changes.
- [ ] Cosmos DB account uses NoSQL API with a `traces` container partitioned on `/agentRunId`.
- [ ] All resources tagged with `env`, `owner`, `costCenter`, `workload`.

### S0-3 — OIDC federation for CI/CD
**As a** release engineer
**I want** GitHub Actions to deploy to Azure via OIDC
**so that** no long-lived credentials live in the repo.

**Acceptance**:
- [ ] `deploy-dev.yml` runs `azure/login@v2` with `client-id`, `tenant-id`, `subscription-id`, **no secret**.
- [ ] A successful end-to-end deployment of the dev infra triggered from a `main` push.
- [ ] Workload identity federation configured for `repo:urruegg/AgenticDevOpsPlatform:ref:refs/heads/main` and `pull_request`.

### S0-4 — Entra app registration for orchestrator
**As a** security reviewer
**I want** the orchestrator agent's Entra identity provisioned and documented
**so that** Sprint 1 can authenticate against Azure resources.

**Acceptance**:
- [ ] App registration `agentic-devops-orchestrator-dev` exists.
- [ ] Federated credential for GitHub Actions configured.
- [ ] RBAC assigned: `Key Vault Secrets User` on dev KV; `Cosmos DB Built-in Data Contributor` on `traces` container; `Reader` on `rg-agentic-devops-dev`.
- [ ] Identity registered in `docs/SECURITY.md` RBAC matrix.

### S0-5 — ADRs for key decisions
**As a** future maintainer
**I want** the rationale for Bicep, Cosmos DB, and OIDC recorded
**so that** decisions aren't relitigated later.

**Acceptance**:
- [ ] `docs/adr/0002-bicep-as-iac.md`, `0003-cosmos-nosql-for-traces.md`, `0004-oidc-federation.md` present, status `Accepted`.

---

## 5. Deliverables

| Artifact | Path |
|----------|------|
| Bicep scaffold | `infra/main.bicep`, `infra/modules/*.bicep` |
| azd config | `azure.yaml` |
| CI/CD workflows | `.github/workflows/ci.yml`, `iac-validate.yml`, `deploy-dev.yml` |
| Python project | `pyproject.toml`, `agents/__init__.py`, `tools/__init__.py`, `tests/__init__.py` |
| Pre-commit | `.pre-commit-config.yaml` |
| ADRs | `docs/adr/0002–0004*.md` |
| PR template | `.github/PULL_REQUEST_TEMPLATE.md` |
| CODEOWNERS | `.github/CODEOWNERS` |

---

## 6. Dependencies

- An Azure subscription with permissions to create app registrations and federated credentials.
- A GitHub repository admin to register OIDC trust + add repo variables.
- Decision on Cosmos DB region (recommend `westeurope` or `swedencentral` for EU residency).

---

## 7. Risks & Mitigations

| Risk | Mitigation |
|------|------------|
| OIDC federation misconfigured → CI cannot deploy | Validate with a no-op `what-if` first; document working `subject` claim format in ADR-0004. |
| Cosmos DB region quota | Check quota before deploy; fall back to `northeurope` if needed. |
| Pre-commit drag on developer velocity | Limit Sprint 0 hooks to format + lint; full hooks (mypy, eval) come in Sprint 1. |

---

## 8. Exit Criteria

- [ ] All user stories above marked done.
- [ ] `deploy-dev.yml` green on `main`.
- [ ] M1 demo executed (see below).
- [ ] Retro completed; any decisions captured as ADRs.

---

## 9. Demo Script (M1)

1. Open a freshly cloned repo on a clean machine.
2. Run `pip install -e .[dev]` → green.
3. Run `pytest -q && ruff check . && black --check .` → green.
4. Push a trivial change to `main` → CI runs, `deploy-dev.yml` deploys infra, what-if returns 0 unintended changes.
5. Open Azure portal → show RG `rg-agentic-devops-dev` with all 4 resources tagged correctly.
6. Show Entra app registration `agentic-devops-orchestrator-dev` with federated credential and RBAC scopes.

---

## 10. Related Documents

- [sprints/SPRINT_PLAN.md](./SPRINT_PLAN.md)
- [docs/INFRASTRUCTURE.md](../docs/INFRASTRUCTURE.md)
- [docs/SECURITY.md](../docs/SECURITY.md)
- [docs/ALM_PLAN.md](../docs/ALM_PLAN.md)
- [docs/adr/README.md](../docs/adr/README.md)
