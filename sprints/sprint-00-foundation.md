# Sprint 0 — Foundation & Tooling

| Field | Value |
|-------|-------|
| **Version** | 1.2.0 |
| **Date** | 2026-05-18 |
| **Author** | Urs Rüegg |
| **Status** | Draft |
| **Previous Version** | 1.0.0 (initial release); 1.1.0 narrowed scope to GitHub Copilot coding-agent setup per SPRINT_PLAN §9 Q1; 1.2.0 adds a runtime-amendment overlay aligning Sprint 0 with [ADR-0002](../docs/adr/0002-runtime-is-github-copilot-coding-agent.md) — the Python skeleton (`pyproject.toml`, `agents/__init__.py`, `tools/__init__.py`, `api/__init__.py`, `tests/__init__.py`, `evals/__init__.py`) and Python lint/format/test hooks (`ruff`, `black`, `pytest`, `pre-commit`) are **not delivered** in this sprint. They are replaced by Markdown lint + link check + golden-task fixture scaffolding. User-story IDs `S0-1..S0-4` are preserved; their acceptance criteria are reinterpreted in §3.1 below. |

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
9. [Demo Script](#9-demo-script)
10. [Related Documents](#10-related-documents)

---

## 1. Goal & Outcomes

Stand up the repository and the **GitHub Copilot coding-agent** so the team can
start building agents in Sprint 1 without any Azure subscription dependency.

By the end of the sprint:

- Python project skeleton (`agents/`, `tools/`, `api/`, `tests/`, `evals/`) with
  lint/format/test wired into CI (no deployment).
- `.github/copilot-instructions.md`, `.github/PULL_REQUEST_TEMPLATE.md`, and
  `AGENTS.md` define how the GitHub Copilot coding agent works in this repo
  (scope guards, traceability contract, MCP servers it may call).
- `.github/workflows/ci.yml` runs lint/test on every PR.
- Repo conventions (CODEOWNERS, issue templates) committed.
- ADR system in place; deferred decisions (hosting subscription, IaC stack,
  OIDC, Entra Agent ID) recorded as `Proposed` ADRs.

---

## 2. Use Cases Addressed

- **None directly** — this is the platform foundation that all three use cases
  depend on.

---

## 3. Scope

### 3.1 Runtime Amendment (per ADR-0002)

The runtime is the **GitHub Copilot coding agent**
([ADR-0002](../docs/adr/0002-runtime-is-github-copilot-coding-agent.md)). The
in-scope list below is reinterpreted accordingly:

- **Python project skeleton, `pyproject.toml`, `ruff`, `black`, `pytest`,
  `pre-commit`** → **dropped from Sprint 0**. There is no Python source code
  in this repo. The repo is Markdown + YAML + Bicep (UC1 outputs).
- **`.github/workflows/ci.yml` runs lint/test** → **runs `markdownlint-cli2`,
  `markdown-link-check`, and `actionlint`**. Bicep validation is added only
  when an `infra/` folder is created (no earlier than Sprint 2).
- **`AGENTS.md`, `CODEOWNERS`, issue templates** → unchanged, still in scope.
- **`.github/copilot/mcp.json`** → added to the deliverables list as part of
  the Copilot coding-agent configuration.
- **ADRs `0002-defer-hosting-subscription`, `0003-bicep-as-iac`,
  `0004-oidc-federation`, `0005-cosmos-nosql-for-traces`** → reinterpreted:
  `0002` is **superseded** by the new [ADR-0002 Runtime is GitHub Copilot
  coding agent](../docs/adr/0002-runtime-is-github-copilot-coding-agent.md);
  `0003` (Bicep) is retained but scoped to UC1 *output* templates;
  `0004` (OIDC) is retained but scoped to UC1's `iac-validate` and customer
  what-if; `0005` (Cosmos for traces) is **superseded** by ADR-0002 (no
  Cosmos at the platform layer).

All user-story IDs (`S0-1`..`S0-4`) below remain stable. Acceptance criteria
are reinterpreted in line with the amendment above (e.g., "`pytest`,
`ruff check`, `black --check` all pass" in `S0-1` becomes "`markdownlint-cli2`
and `markdown-link-check` pass"; "`mypy --strict` and Pydantic enforcement in
CI" in `NFR-MAINT-001` is vacuously satisfied while no Python exists).

### In Scope
- Python project: `pyproject.toml` (Python 3.11+), `ruff`, `black`, `pytest`, `pre-commit`.
- Python project skeleton: `agents/__init__.py`, `tools/__init__.py`, `api/__init__.py`, `tests/__init__.py`, `evals/__init__.py`.
- Repo conventions: `.github/PULL_REQUEST_TEMPLATE.md` (already present), `.github/copilot-instructions.md` (already present), `AGENTS.md`, `CODEOWNERS`, issue templates.
- GitHub Copilot coding-agent configuration: MCP server allowlist, scope guards documented, branch/PR conventions, traceability contract enforced via [docs/PRD.md](../docs/PRD.md).
- GitHub Actions: `ci.yml` only (lint + test, **no deploy**).
- ADRs: `0002-defer-hosting-subscription.md` (Proposed), `0003-bicep-as-iac.md` (Proposed), `0004-oidc-federation.md` (Proposed), `0005-cosmos-nosql-for-traces.md` (Proposed). All deferred to the sprint that activates them.

### Out of Scope (deferred per [SPRINT_PLAN.md §9 Q1](./SPRINT_PLAN.md#9-open-questions--resolutions))
- Any Azure resource provisioning (Cosmos DB, Key Vault, Log Analytics, App Insights, RG).
- `infra/main.bicep` and module library — created when a hosting subscription is chosen.
- `azure.yaml` (azd) and `deploy-*.yml` workflows.
- OIDC federation between GitHub and Azure (depends on hosting subscription).
- Entra app registration and Agent ID provisioning (depends on hosting tenant).
- Any agent logic (Sprint 1).
- WorkIQ / ADO MCP setup (Sprint 1 / Sprint 2).
- Private endpoints, `prod` environment (Sprint 6).

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
- [ ] *Implements*: `FR-PLT-001`, `NFR-MAINT-001`.

### S0-2 — GitHub Copilot coding-agent setup
**As a** developer
**I want** the GitHub Copilot coding agent configured for this repo with
clear scope guards, MCP allowlist, and the traceability contract
**so that** every Copilot-authored PR follows our conventions from day one.

**Acceptance**:
- [ ] `.github/copilot-instructions.md` present and current (already done).
- [ ] `.github/PULL_REQUEST_TEMPLATE.md` requires `FR-*` / `NFR-*` IDs (already done; verifies `NFR-GOV-006`).
- [ ] `AGENTS.md` documents agent personas in this repo, the MCP servers allowed (GitHub, WorkIQ, ADO once available), and where prompts/skills live.
- [ ] `CODEOWNERS` covers `agents/`, `tools/`, `infra/`, `docs/`, `.github/`.
- [ ] Copilot coding agent can pick up an issue, open a feature branch, and produce a PR that passes CI and links to PRD requirement IDs.
- [ ] *Implements*: `FR-PLT-001`, `NFR-GOV-006`, `NFR-MAINT-002`.

### S0-3 — CI workflow (no deploy)
**As a** release engineer
**I want** GitHub Actions to run lint + test on every PR
**so that** quality gates fire without needing an Azure subscription.

**Acceptance**:
- [ ] `.github/workflows/ci.yml` runs `ruff check .`, `black --check .`, `pytest -q` on every PR + push to `main`.
- [ ] Branch protection on `main` requires `ci` green and at least one review.
- [ ] No workflow references an Azure subscription, tenant, or OIDC client — deploy workflows are deferred.
- [ ] *Implements*: `NFR-MAINT-001`, `NFR-MAINT-003`.

### S0-4 — Proposed ADRs for deferred decisions
**As a** future maintainer
**I want** the deferred decisions (hosting subscription, IaC stack, OIDC, Cosmos trace store) recorded
**so that** the rationale survives until the sprint that activates them.

**Acceptance**:
- [ ] `docs/adr/0002-defer-hosting-subscription.md` (status `Proposed`) references [SPRINT_PLAN.md §9 Q1](./SPRINT_PLAN.md#9-open-questions--resolutions).
- [ ] `docs/adr/0003-bicep-as-iac.md`, `0004-oidc-federation.md`, `0005-cosmos-nosql-for-traces.md` exist as `Proposed`, each noting the sprint that will promote them to `Accepted`.
- [ ] *Implements*: `NFR-GOV-001`, `NFR-MAINT-002`.

---

## 5. Deliverables

| Artifact | Path |
|----------|------|
| Python project | `pyproject.toml`, `agents/__init__.py`, `tools/__init__.py`, `api/__init__.py`, `tests/__init__.py`, `evals/__init__.py` |
| Pre-commit | `.pre-commit-config.yaml` |
| CI workflow | `.github/workflows/ci.yml` |
| Copilot agent config | `.github/copilot-instructions.md` (present), `.github/PULL_REQUEST_TEMPLATE.md` (present), `AGENTS.md`, `.github/CODEOWNERS`, `.github/ISSUE_TEMPLATE/*.yml` |
| Proposed ADRs | `docs/adr/0002-defer-hosting-subscription.md`, `0003-bicep-as-iac.md`, `0004-oidc-federation.md`, `0005-cosmos-nosql-for-traces.md` |

---

## 6. Dependencies

- A GitHub repository admin to set branch protection and enable the GitHub Copilot coding agent on the repo.
- Access to the GitHub MCP server in the Copilot agent runtime (already in the workspace).
- **No Azure subscription required** — deferred per [SPRINT_PLAN.md §9 Q1](./SPRINT_PLAN.md#9-open-questions--resolutions).

---

## 7. Risks & Mitigations

| Risk | Mitigation |
|------|------------|
| Copilot coding agent ignores repo conventions | Lock conventions in `.github/copilot-instructions.md` + `AGENTS.md`; reviewer checklist in PR template catches drift. |
| Pre-commit drag on developer velocity | Limit Sprint 0 hooks to format + lint; full hooks (mypy, eval) come in Sprint 1. |
| Deferred decisions get forgotten | `Proposed` ADRs link back to [SPRINT_PLAN.md §9](./SPRINT_PLAN.md#9-open-questions--resolutions); each ADR names the sprint that activates it. |

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
4. Open a sample issue tagged for the Copilot coding agent; agent opens a feature branch and a PR; CI runs green; PR description includes the requirement IDs the change implements (per the PR template).
5. Show `.github/copilot-instructions.md`, `AGENTS.md`, and `docs/PRD.md` traceability matrix — explain how the next sprint plugs in.
6. Walk through the four `Proposed` ADRs and the sprint each will activate in.

---

## 10. Related Documents

- [sprints/SPRINT_PLAN.md](./SPRINT_PLAN.md)
- [docs/INFRASTRUCTURE.md](../docs/INFRASTRUCTURE.md)
- [docs/SECURITY.md](../docs/SECURITY.md)
- [docs/ALM_PLAN.md](../docs/ALM_PLAN.md)
- [docs/adr/README.md](../docs/adr/README.md)
