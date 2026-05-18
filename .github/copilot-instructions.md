# Copilot Instructions — Agentic DevOps Platform

| Field | Value |
|-------|-------|
| **Version** | 1.0 |
| **Date** | 2026-05-18 |
| **Author** | Urs Rüegg |
| **Status** | Draft |
| **Previous Version** | — (initial release) |

This repository hosts a sample **Agentic DevOps Platform**: a system where AI agents
plan, execute, and observe DevOps workflows (CI/CD, infrastructure provisioning,
incident response, cost/compliance) on Microsoft Azure.

Use these instructions to guide all code, documentation, and review suggestions in
this repo.

---

## Table of Contents

1. [Project Architecture](#1-project-architecture)
2. [Build & Test Commands](#2-build--test-commands)
3. [Coding Conventions](#3-coding-conventions)
4. [Security](#4-security)
5. [Testing Strategy](#5-testing-strategy)
6. [Commit & PR Conventions](#6-commit--pr-conventions)
7. [Code Review Checklist](#7-code-review-checklist)
8. [Naming Conventions](#8-naming-conventions)

---

## 1. Project Architecture

### Repository Structure
> The repository is in an early stage. Folders marked *(planned)* are conventions
> agents should follow when creating new code; do not invent alternative layouts.

| Folder | Stack | Purpose |
|--------|-------|---------|
| `agents/` *(planned)* | Python 3.11+, Microsoft Agent Framework / Semantic Kernel | Planner / executor / critic orchestrators, agent prompts, evaluations |
| `tools/` *(planned)* | Python 3.11+ | Tool/skill adapters for Azure, GitHub, and CI/CD systems |
| `api/` *(planned)* | Python 3.11+, FastAPI *(or)* TypeScript, Node 20+ | HTTP entrypoint for agent invocation and webhook handlers |
| `infra/` *(planned)* | Bicep | IaC — resource groups, identity, Key Vault, Cosmos DB, App Insights, hosting |
| `tests/` *(planned)* | pytest / vitest | Unit and integration tests |
| `evals/` *(planned)* | Python | Golden tasks, evaluation harness, agent trace fixtures |
| `.github/workflows/` *(planned)* | GitHub Actions | CI/CD pipelines (lint, test, scan, IaC validate, deploy via OIDC) |
| `docs/` *(planned)* | Markdown | Architecture, security, AI governance, ADRs |

### Key Documentation (read before making significant changes)

When `docs/ARTEFACTS.md` exists, treat it as the single entry point. Until then,
consult the relevant docs listed below before modifying architecture, data models,
security, or agent behavior.

#### Solution-Level Docs (`docs/` — create when first needed)
| Document | Purpose | Read before changing... |
|----------|---------|------------------------|
| `docs/PRD.md` | Product requirements: personas, user journeys, FR/NFR catalogue with stable IDs, traceability matrix | Any scope/feature/requirement change; ALWAYS read before writing user stories or PRs |
| `docs/ARCHITECTURE.md` | System architecture, agent topology, integrations, hosting | Service boundaries, agent contracts, infra topology |
| `docs/AI.md` | Responsible AI guidelines, agent governance, model selection, prompt patterns | Agent prompts, model upgrades, RAI compliance |
| `docs/SECURITY.md` | Zero Trust, identity, managed identity, auth, secrets, RBAC | Auth flows, Key Vault, RBAC, CORS |
| `docs/DATA.md` | Agent memory, trace storage, Cosmos DB partitioning, retention | Data models, partition keys, retention |
| `docs/INFRASTRUCTURE.md` | Azure resource inventory, Bicep modules, environments | Infra provisioning, environment config |
| `docs/ALM_PLAN.md` | CI/CD pipelines, OIDC federation, deployment strategy | Workflows, release process, rollback |
| `docs/TEST.md` | Test strategy, coverage thresholds, eval harness | Test patterns, eval gates |
| `docs/adr/NNNN-title.md` | Architecture Decision Records | Any cross-cutting change |

> **Rule**: When working on a sub-component (agent, tool, infra module), read its
> local README first, then fall back to the solution-level docs above for
> cross-cutting concerns (security, data, infrastructure, AI governance).

### Agent Decision Order
1. Identify target scope (folder / sub-component).
2. Read docs in this order: local README → solution-level cross-cutting docs (`docs/*`).
3. Implement minimal code changes in the correct layer (`agent` / `tool` / `api` / `infra`).
4. Run the most specific tests first, then broader project tests, then evals if agent behavior changed.
5. Validate cross-cutting impact: prompts, tool contracts, RBAC, infra, security, docs.

### Scope Guards (mandatory)
- Changes in `agents/**`: read `agents/README.md` and `docs/AI.md` first; if tool
  contracts change, also read `tools/README.md` and `docs/ARCHITECTURE.md`.
- Changes in `tools/**`: read `tools/README.md` and `docs/SECURITY.md` first; any
  new tool must declare schema, side effects, and required permissions.
- Changes in `api/**`: read `docs/ARCHITECTURE.md` and `docs/SECURITY.md` before
  changing routes or auth.
- Changes in `infra/**`: read `docs/INFRASTRUCTURE.md` and `docs/ALM_PLAN.md`
  before updating Bicep modules.
- Changes in `.github/workflows/**`: read `docs/ALM_PLAN.md` and `docs/SECURITY.md`
  (OIDC, secrets) before editing.
- Changes in `evals/**`: read `docs/AI.md` and `docs/TEST.md` first.

### Key Technical Decisions
- **Cloud**: Microsoft Azure only. No multi-cloud abstractions unless explicitly required.
- **IaC**: **Bicep** is the default. Use Terraform only when multi-cloud or an
  existing verified module mandates it.
- **Identity**: **Managed Identity** for every service-to-service connection
  (App Service → Key Vault, App Service → Cosmos DB, Functions → Storage, etc.).
  No connection strings or client secrets in code or config.
- **Secrets**: **Azure Key Vault**, referenced via Key Vault references or RBAC.
- **Agent memory & traces**: **Azure Cosmos DB (NoSQL API)** with a high-cardinality
  partition key (`tenantId`, `sessionId`, or `agentRunId`). Use Hierarchical
  Partition Keys when a single logical partition could exceed 20 GB.
- **Observability**: Azure Monitor + Application Insights + OpenTelemetry from
  day one. Every agent run emits a trace (inputs, tool calls, outputs, latency, cost).
- **CI/CD**: GitHub Actions with **OIDC federation** to Azure. No long-lived secrets.
- **Environments**: `dev` → `test` → `prod`, separated by resource group and tags.

---

## 2. Build & Test Commands

> Commands below are the conventions for this repo. Add concrete scripts to
> `package.json` / `pyproject.toml` / workflows as components are created.

```bash
# Python (agents, tools, api, evals)
py -3.11 -m pip install -r requirements.txt   # or: pip install -e .[dev]
py -3.11 -m pytest -q                          # run all unit tests
py -3.11 -m ruff check .                       # lint
py -3.11 -m black --check .                    # format check

# TypeScript / Node (if api/ uses Node)
npm ci
npm run lint
npm test
npm run build

# IaC (Bicep)
az bicep build --file infra/main.bicep                   # compile
az deployment group what-if -g <rg> -f infra/main.bicep  # dry-run before any apply

# Evaluations (when evals/ is present)
py -3.11 -m pytest evals/ -q
```

---

## 3. Coding Conventions

### Do / Don't (Agent Guardrails)
- **Do** keep changes minimal and scoped to the requested task.
- **Do** follow existing patterns in adjacent files before introducing new patterns.
- **Do** update tests and docs when behavior or contracts change.
- **Do** surface assumptions you made when context is incomplete.
- **Don't** hard-code subscription IDs, tenant IDs, resource names, URLs, or secrets.
- **Don't** introduce new frameworks, runtimes, or cloud providers without justification.
- **Don't** produce destructive commands (delete, drop, force-push, scale-to-zero,
  `rm -rf`, `terraform destroy`, `az ... delete`) without a dry-run and explicit
  user confirmation.
- **Don't** add tool/agent capabilities that bypass the dry-run / plan stage.

### General principles
- Prefer **clarity over cleverness**. Code should be readable by an on-call engineer.
- Keep functions small and single-purpose; favor pure functions where practical.
- Validate inputs at trust boundaries (HTTP, queues, agent tool calls).
- Fail fast with actionable error messages; never swallow exceptions silently.
- Add comments only to explain *why*, not *what*.

### Backend (Python 3.11+)
- Type hints required on public functions; validate structured data with `pydantic`.
- Format with `black`, lint with `ruff`; fix all warnings before committing.
- Use `async`/`await` for I/O; never block the event loop with sync HTTP calls.
- Use `httpx.AsyncClient` (or the SDK's async client) as a long-lived singleton.
- Log with the `logging` module: structured key-value extras, no f-strings inside
  log templates, never log secrets or tokens.

### Frontend / API (TypeScript, if used)
- Node 20+, strict TS config, ESM modules.
- Lint with ESLint, format with Prettier.
- Validate request/response shapes at the boundary (e.g., `zod`).

### Shell & PowerShell
- Bash: `set -euo pipefail` at top of every script.
- PowerShell 7+: `Set-StrictMode -Version Latest` and `$ErrorActionPreference = 'Stop'`.

### IaC (Bicep)
- One module per resource type under `infra/modules/`; compose from `infra/main.bicep`.
- Parameterise environment (`dev` / `test` / `prod`); never hard-code names.
- Tag every resource: `env`, `owner`, `costCenter`, `workload`.
- Enable diagnostic settings → Log Analytics for every production resource.
- Run `what-if` before any `az deployment ... create`.

### Agentic patterns
- Treat agents as **deterministic where possible**: structured outputs, JSON
  schemas, explicit tool contracts.
- Every tool/skill must declare: **name, description, input schema, output schema,
  side effects, required permissions**.
- Always provide a **dry-run / plan mode** before any mutating action
  (deploy, delete, scale, restart).
- Persist agent traces (inputs, tool calls, outputs, cost, latency) to Cosmos DB
  or App Insights for replay and evaluation.
- Treat LLM output as **untrusted input**: validate and sanitise before passing to
  tools, shells, or SQL/KQL queries.
- Any prompt or agent-behavior change must be backed by an eval run in `evals/`.

### Cosmos DB usage
- Reuse a singleton `CosmosClient`.
- Handle `429 Too Many Requests` with retry-after honoured by the SDK.
- Log SDK diagnostics on latency spikes or unexpected status codes.
- Choose a high-cardinality partition key; document it in `docs/DATA.md`.

---

## 4. Security

- Follow the **OWASP Top 10**; flag and fix vulnerable patterns on sight.
- **Authentication**: Managed Identity for service-to-service; Entra ID for human
  callers. Require authentication on every endpoint by default; opt out explicitly
  with a comment justifying why.
- **Secrets**: Azure Key Vault only. Never log or commit secrets, tokens,
  connection strings, or PII.
- **RBAC**: Least privilege. Prefer built-in roles; scope at the resource or
  resource group level (never subscription unless required).
- **Tool inputs**: Validate and sanitise all agent tool inputs. Treat any value
  derived from an LLM as untrusted.
- **Destructive actions**: Delete, drop, force-push, scale-to-zero, and
  `terraform destroy` require an explicit, separate confirmation step.
  Do **not** auto-approve in code paths or prompts.
- **Egress**: Use private endpoints for Key Vault, Cosmos DB, and Storage in
  production. CORS allow-lists, never `*`.

---

## 5. Testing Strategy

- **Test-first**: Write tests before implementing features or fixing bugs.
- **Coverage target**: ≥ 80% line coverage on changed files. PRs must not
  decrease overall coverage.
- **Unit tests**: `pytest` (Python) or `vitest`/`jest` (TS). Mock external
  services (Azure SDK clients, HTTP, Cosmos DB).
- **Integration tests**: Required for every new agent tool/skill; cover the
  happy path plus at least one failure mode.
- **Agent evaluations**: Any change to prompts, tools, or agent control flow
  must run the `evals/` harness and post results in the PR.
- **All tests must pass in CI** before merge. No flaky tests — fix or remove.

---

## 6. Commit & PR Conventions

### Commit Messages
Use [Conventional Commits](https://www.conventionalcommits.org/):

| Prefix | When to use | Triggers release? |
|--------|-------------|-------------------|
| `fix:` | Bug fix | Patch (x.x.+1) |
| `feat:` | New feature | Minor (x.+1.0) |
| `feat!:` or `BREAKING CHANGE:` | Breaking change | Major (+1.0.0) |
| `docs:` | Documentation only | No |
| `ci:` | CI/CD workflow changes | No |
| `refactor:` | Code change that neither fixes nor adds | No |
| `test:` | Adding or updating tests | No |
| `perf:` | Performance improvement | No |
| `chore:` | Maintenance (deps, config) | No |

### Branch & PR Model
- **Single-branch model**: all work lands on `main`.
- Copilot coding agent creates feature branches automatically from issues.
- Use the PR template at `.github/PULL_REQUEST_TEMPLATE.md` (create if missing).

### PR Output Contract (for agents)
PR description must include:
- **What changed** (by file/area)
- **Why** (issue/requirement link)
- **Requirements implemented** — list every `FR-*` / `NFR-*` ID from `docs/PRD.md` advanced by this PR. Required by `NFR-GOV-006`. Use `partial:` if not fully verified.
- **Test evidence** (commands run + pass/fail summary)
- **Agent/eval impact** (eval scores before/after, golden-task delta)
- **API impact** (new/changed endpoints, tool contracts)
- **Infra impact** (Bicep modules added/changed, `what-if` summary)
- **Security impact** (new permissions, secrets, identities)

### Agent PR Completion Contract (hard gate)
Agents must not create or mark a PR ready for review unless **all** points below
are satisfied:
- **Scope contract**: Change set is limited to the approved issue scope and
  allowed folders. Unrelated file edits are excluded or explicitly approved.
- **Validation contract**: Required build/lint/test commands for affected
  components are executed. PR includes command-level validation evidence.
- **Eval contract**: If prompts, tools, or agent control flow changed, the
  `evals/` harness was run and results are attached.
- **Documentation contract**: Relevant docs are updated when behavior, contracts,
  security, or operations changed. If no doc update is required, PR states
  explicit justification.
- **Commit contract**: Commit messages follow Conventional Commits. Branch and
  PR are linked to the governing issue(s).
- **Traceability contract**: PR description lists every `FR-*` / `NFR-*` ID from
  `docs/PRD.md` it implements. If a new requirement is introduced or scope shifts,
  `docs/PRD.md` §7 (traceability matrix) is updated in the same PR. Tests and
  eval YAMLs reference the requirement ID(s) they verify (`requirement:` key or
  docstring tag, e.g. `"""Verifies FR-UC1-005"""`).
- **Impact contract**: PR includes API, infrastructure, security, and eval
  impact statements. If impact is none, PR states `none` explicitly.
- **Review handoff contract**: PR lists residual risks/open questions and the
  agent summarises what should be reviewed first.

---

## 7. Code Review Checklist

Before approving a PR, verify:
- [ ] All CI checks pass (lint, test, build, security scan, IaC validate)
- [ ] New code has unit tests (≥ 80% coverage for changed files)
- [ ] New agent tools have integration tests and a declared input/output schema
- [ ] Prompt or agent-behavior changes include eval results
- [ ] PR lists the `FR-*` / `NFR-*` IDs it implements; `docs/PRD.md` §7 is consistent
- [ ] No hard-coded secrets, subscription IDs, tenant IDs, URLs, or resource names
- [ ] New endpoints require authentication unless explicitly justified
- [ ] Error handling is structured and never leaks secrets to clients
- [ ] Commit messages follow Conventional Commits format

### Change Impact Checklist (before merge)
- [ ] Documentation updated where behavior/contracts changed (`docs/*` or local README)
- [ ] Security impact assessed (identity, RBAC, secrets, network)
- [ ] Data impact assessed (Cosmos DB partition key, retention, PII)
- [ ] Infrastructure impact assessed (Bicep modules, `what-if` clean, tags applied)
- [ ] AI/eval impact assessed (golden-task scores, RAI considerations)

---

## 8. Naming Conventions

- **Files & folders**: lowercase with hyphens (`agent-runner.py`, `cost-tool.ts`).
  Exception: Python modules use snake_case (`agent_runner.py`), React components
  use PascalCase (`AgentTraceView.tsx`).
- **Python**: `snake_case` for functions/variables, `PascalCase` for classes,
  `UPPER_SNAKE` for constants.
- **C# / TypeScript classes**: PascalCase. TS interfaces: no `I` prefix.
- **Bicep resources**: `kebab-case` with environment suffix
  (e.g., `kv-agentic-devops-dev`, `cosmos-agentic-devops-prod`).
- **Resource tags**: `env`, `owner`, `costCenter`, `workload` on every resource.
- **Git tags**: `vX.Y.Z` — managed by release tooling, never manual.
- **Agent tool names**: `verb_noun` snake_case (`deploy_bicep`, `query_log_analytics`,
  `restart_app_service`).
