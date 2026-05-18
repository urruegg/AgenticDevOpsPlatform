# Sprint 0 — Foundation & Tooling

| Field | Value |
|-------|-------|
| **Version** | 2.0.0 |
| **Date** | 2026-05-18 |
| **Author** | Urs Rüegg |
| **Status** | Draft |
| **Previous Version** | 1.0.0 (initial release); 1.1.0 narrowed scope to GitHub Copilot coding-agent setup per SPRINT_PLAN §9 Q1; 1.2.0 added a runtime-amendment overlay aligning with [ADR-0002](../docs/adr/0002-runtime-is-github-copilot-coding-agent.md); 2.0.0 MAJOR — drops the 1.x Python project skeleton (`pyproject.toml`, `agents/__init__.py`, `tools/__init__.py`, `api/__init__.py`, `tests/__init__.py`, `evals/__init__.py`, `ruff`, `black`, `pytest`, `pre-commit`) and the 1.2.0 amendment-overlay structure. Replaces them with the final GitHub Copilot coding-agent foundation (Markdown + MCP allow-list + GitHub-native CI). User-story IDs `S0-1..S0-4` preserved; acceptance criteria restated in final form. |

> **Window**: 2026-05-18 → 2026-05-22 (1 week bootstrap)
> **Theme**: Bootstrap the repository and the **GitHub Copilot coding-agent**
> setup so the team can start building agents in Sprint 1.
>
> **Scope decision** (per [SPRINT_PLAN.md §9 Q1](./SPRINT_PLAN.md#9-open-questions--resolutions)):
> **subscription-independent** — no Azure resources are provisioned in this
> sprint. Cosmos DB / Key Vault / Log Analytics / App Insights, OIDC
> federation, and Entra app registrations are deferred to the first sprint
> that needs durable state.

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
9. [Demo Script](#9-demo-script-m1)
10. [Related Documents](#10-related-documents)

---

## 1. Goal & Outcomes

Stand up the repository and the **GitHub Copilot coding-agent** configuration
so the team can start building agents in Sprint 1 without any Azure
subscription dependency.

By the end of the sprint:

- `.github/copilot-instructions.md`, `.github/PULL_REQUEST_TEMPLATE.md`, and
  `AGENTS.md` define how the GitHub Copilot coding agent works in this repo
  (scope guards, traceability contract, MCP servers it may call).
- `.github/copilot/mcp.json` enumerates the allowed MCP servers (initially
  `github-mcp` only — others added in the sprint that needs them).
- `.github/CODEOWNERS`, `.github/ISSUE_TEMPLATE/`, and at least one issue
  template (`smoke-echo.yml`) are in place.
- `.github/workflows/ci.yml` runs `markdownlint-cli2`, lychee link check, and
  `actionlint` on every PR. Bicep build is added the sprint `infra/` is
  introduced.
- ADR system in place; deferred decisions recorded as `Proposed` ADRs.

---

## 2. Use Cases Addressed

- **None directly** — this is the platform foundation that all three use cases
  depend on.

---

## 3. Scope

### In Scope
- `.github/copilot-instructions.md`, `.github/PULL_REQUEST_TEMPLATE.md`, `AGENTS.md`, `.github/CODEOWNERS`, `.github/ISSUE_TEMPLATE/`.
- GitHub Copilot coding-agent configuration: `.github/copilot/mcp.json` MCP allow-list (initially `github-mcp` only); scope guards documented; branch/PR conventions; traceability contract enforced via [docs/PRD.md](../docs/PRD.md).
- `.github/workflows/ci.yml`: markdown lint (`markdownlint-cli2`), link check (`lycheeverse/lychee-action`), workflow lint (`actionlint`). **No deploy workflows.**
- `lychee.toml` at repo root (single source of truth for link-check options).
- `scripts/preflight.ps1` — local pre-checkin script that mirrors every CI job.
- ADRs: `0002-runtime-is-github-copilot-coding-agent` (Accepted), `0003-bicep-as-iac` (Proposed), `0004-oidc-federation` (Proposed). Each Proposed ADR names the sprint that promotes it to Accepted.

### Out of Scope (per [ADR-0002](../docs/adr/0002-runtime-is-github-copilot-coding-agent.md))
- **Any Azure resource provisioning at the platform layer** — no Cosmos DB, no Key Vault, no Log Analytics, no App Insights, no resource groups. The platform owns no Azure infrastructure of its own.
- Any Python / TypeScript source code, runtime, lint, or test toolchain. The repo is Markdown + YAML + Bicep only (Bicep arrives in Sprint 2 as UC1 *output*).
- OIDC federation between GitHub and Azure (deferred until a workflow needs to call Azure — earliest Sprint 2 for `az bicep what-if`).
- Entra app registration / Agent ID provisioning.
- Any agent prompt file (Sprint 1).
- WorkIQ / Azure DevOps MCP enablement (Sprint 2 / Sprint 4).

---

## 4. User Stories & Acceptance Criteria

### S0-1 — Repo scaffold
**As a** developer
**I want** the Markdown + GitHub configuration pre-wired with quality gates
**so that** every future PR lands with markdown lint, link check, and workflow
lint enforced from day one.

**Acceptance**:
- [ ] `scripts/preflight.ps1` runs `markdownlint-cli2`, `lychee`, `actionlint` and exits 0 on a clean clone.
- [ ] `lychee.toml` at repo root pins link-check options (shared by CI and preflight).
- [ ] No source-code toolchain (no `pyproject.toml`, no `package.json`, no `tsconfig.json`).
- [ ] *Implements*: `FR-PLT-001`, `NFR-MAINT-001`.

### S0-2 — GitHub Copilot coding-agent setup
**As a** developer
**I want** the GitHub Copilot coding agent configured for this repo with
clear scope guards, MCP allow-list, and the traceability contract
**so that** every Copilot-authored PR follows our conventions from day one.

**Acceptance**:
- [ ] `.github/copilot-instructions.md` present and current.
- [ ] `.github/PULL_REQUEST_TEMPLATE.md` requires `FR-*` / `NFR-*` IDs (verifies `NFR-GOV-006`).
- [ ] `AGENTS.md` documents each agent's name, owner, trigger, MCP servers in use, side-effect ceiling, and golden-task path.
- [ ] `.github/copilot/mcp.json` enumerates the allowed MCP servers; additions go through CODEOWNERS-approved PRs.
- [ ] `.github/CODEOWNERS` covers `agents/`, `infra/`, `docs/`, `.github/`.
- [ ] `.github/ISSUE_TEMPLATE/smoke-echo.yml` exists; the Copilot coding agent can pick it up, open a feature branch, and produce a PR that passes CI and links to PRD requirement IDs.
- [ ] *Implements*: `FR-PLT-001`, `NFR-GOV-006`, `NFR-MAINT-002`.

### S0-3 — CI workflow (no deploy)
**As a** release engineer
**I want** GitHub Actions to run lint + link check + workflow lint on every PR
**so that** quality gates fire without needing an Azure subscription.

**Acceptance**:
- [ ] `.github/workflows/ci.yml` runs `markdownlint-cli2`, `lycheeverse/lychee-action`, and `raven-actions/actionlint` on every PR + push to `main`.
- [ ] Branch protection on `main` requires `ci` green and at least one review.
- [ ] No workflow references an Azure subscription, tenant, or OIDC client — deploy workflows are deferred.
- [ ] *Implements*: `NFR-MAINT-001`, `NFR-MAINT-003`.

### S0-4 — Proposed ADRs for deferred decisions
**As a** future maintainer
**I want** the deferred decisions (IaC stack, OIDC) recorded as Proposed ADRs
**so that** the rationale survives until the sprint that activates them.

**Acceptance**:
- [ ] `docs/adr/0002-runtime-is-github-copilot-coding-agent.md` (Accepted) — the runtime decision.
- [ ] `docs/adr/0003-bicep-as-iac.md` (Proposed) — promoted to Accepted in Sprint 2 when `infra/landing-zone/` lands.
- [ ] `docs/adr/0004-oidc-federation.md` (Proposed) — promoted when a workflow first needs to call Azure on behalf of UC1.
- [ ] *Implements*: `NFR-GOV-001`, `NFR-MAINT-002`.

---

## 5. Deliverables

| Artifact | Path |
|----------|------|
| Copilot agent config | `.github/copilot-instructions.md`, `.github/PULL_REQUEST_TEMPLATE.md`, `AGENTS.md`, `.github/CODEOWNERS`, `.github/ISSUE_TEMPLATE/smoke-echo.yml`, `.github/copilot/mcp.json` |
| CI workflow | `.github/workflows/ci.yml` |
| Link-check config | `lychee.toml` |
| Preflight | `scripts/preflight.ps1` |
| ADRs | `docs/adr/0002-runtime-is-github-copilot-coding-agent.md` (Accepted), `docs/adr/0003-bicep-as-iac.md` (Proposed), `docs/adr/0004-oidc-federation.md` (Proposed) |

---

## 6. Dependencies

- A GitHub repository admin to set branch protection and enable the GitHub Copilot coding agent on the repo.
- Access to the GitHub MCP server in the Copilot agent runtime.
- **No Azure subscription required** (per [ADR-0002](../docs/adr/0002-runtime-is-github-copilot-coding-agent.md)).

---

## 7. Risks & Mitigations

| Risk | Mitigation |
|------|------------|
| Copilot coding agent ignores repo conventions | Lock conventions in `.github/copilot-instructions.md` + `AGENTS.md`; reviewer checklist in PR template catches drift. |
| CI link-check noise blocks PRs | Configure `lychee.toml` to exclude mail + loopback; allow-list known false-positives. |
| Deferred decisions get forgotten | Each `Proposed` ADR names the sprint that activates it; SPRINT_PLAN §9 cross-references. |

---

## 8. Exit Criteria

- [ ] All user stories above marked done.
- [ ] CI green on `main`.
- [ ] M1 demo executed (see below).
- [ ] Retro completed; any decisions captured as ADRs.

---

## 9. Demo Script (M1)

1. Open a freshly cloned repo on a clean machine.
2. Run `scripts/preflight.ps1` → green (markdownlint 0 errors, lychee 0 errors, actionlint pass).
3. Open the smoke-echo issue (`.github/ISSUE_TEMPLATE/smoke-echo.yml`); the Copilot coding agent opens a feature branch and a draft PR; CI runs green; PR description includes the requirement IDs the change implements (per the PR template).
4. Show `.github/copilot-instructions.md`, `AGENTS.md`, `.github/copilot/mcp.json`, and `docs/PRD.md` traceability matrix — explain how the next sprint plugs in.
5. Walk through the three foundation ADRs and the sprint that activates each Proposed ADR.

---

## 10. Related Documents

- [sprints/SPRINT_PLAN.md](./SPRINT_PLAN.md)
- [docs/INFRASTRUCTURE.md](../docs/INFRASTRUCTURE.md)
- [docs/SECURITY.md](../docs/SECURITY.md)
- [docs/ALM_PLAN.md](../docs/ALM_PLAN.md)
- [docs/adr/README.md](../docs/adr/README.md)
