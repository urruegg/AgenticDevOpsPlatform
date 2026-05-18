# Copilot Instructions — Agentic DevOps Platform

| Field | Value |
|-------|-------|
| **Version** | 2.0.0 |
| **Date** | 2026-05-18 |
| **Author** | Urs Rüegg |
| **Status** | Draft |
| **Previous Version** | 1.1.0 (added §9 SemVer policy); 2.0.0 reframes §§1–8 around the **GitHub Copilot coding agent runtime** per [ADR-0002](../docs/adr/0002-runtime-is-github-copilot-coding-agent.md) — retires Python/Foundry runtime assumptions, drops `agents/tools/api/evals` Python folder conventions, replaces Cosmos DB "primary store" guidance, refocuses CI on markdown lint + Bicep validate. §9 SemVer policy retained verbatim. |

This repository hosts a sample **Agentic DevOps Platform**: a system where AI agents
plan, execute, and observe DevOps workflows (CI/CD, infrastructure provisioning,
incident response, cost/compliance) on Microsoft Azure.

**Runtime (per [ADR-0002](../docs/adr/0002-runtime-is-github-copilot-coding-agent.md)):**
Every agent in this platform is realised as a **GitHub Copilot coding agent**
configured by assets in this repository — `AGENTS.md`, prompt files under
`agents/`, this `copilot-instructions.md`, `.github/copilot/mcp.json`,
ISSUE_TEMPLATE/, PR template, golden-task fixtures, and Bicep template
libraries (UC1 outputs). There is **no bespoke Python service, no Foundry-hosted
agent, and no platform-runtime Azure infrastructure** in this repo. Agents act
on Azure / Azure DevOps / Microsoft 365 *targets* via MCP servers.

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
9. [Document Versioning](#9-document-versioning)

---

## 1. Project Architecture

### Repository Structure
> The repository is in an early stage. Folders marked *(planned)* are conventions
> agents should follow when creating new code; do not invent alternative layouts.
>
> **Important**: There is no Python service code, no FastAPI/Node API, and no
> hosted agent runtime in this repo. Per
> [ADR-0002](../docs/adr/0002-runtime-is-github-copilot-coding-agent.md), agents
> are realised as **Markdown prompt files** and **MCP server configuration**.
> Any source code created by a use case (e.g., a helper script committed by
> a future UC) lives behind a clearly named folder and is treated as the
> exception, not the rule.

| Folder | Stack | Purpose |
|--------|-------|---------|
| `AGENTS.md` *(planned, top-level)* | Markdown | Top-level agent registry: one row per agent (name, owner, trigger, MCP servers in use, side-effect ceiling, golden-task path). Read by the Copilot coding agent on every run. |
| `.github/copilot-instructions.md` | Markdown | This file. Repo-wide conventions and contracts for the Copilot coding agent. |
| `.github/copilot/` *(planned)* | JSON / Markdown | Copilot coding-agent configuration: `mcp.json` allow-list, optional per-agent overrides. |
| `.github/ISSUE_TEMPLATE/` *(planned)* | YAML | Issue templates that drive agent invocation (`uc1-build-subscription.yml`, `uc2-drift-scan.yml`, `uc3-pr-review.yml`, etc.). |
| `.github/PULL_REQUEST_TEMPLATE.md` *(exists)* | Markdown | PR template enforcing the PR Output Contract (§6). |
| `.github/workflows/` *(planned)* | GitHub Actions YAML | CI: markdown lint, Bicep build/validate, security/secret scans, optional eval-on-fixtures workflows. UC2 nightly scheduler workflow opens an issue for the drift agent. |
| `agents/` *(planned)* | Markdown | One folder per agent: `<agent-name>/AGENT.md` (system prompt + tool-call rules + refusal rules), `golden-tasks.md` (acceptance fixtures), `runbook.md`. Markdown only — no source code. |
| `evals/` *(planned)* | Markdown / YAML | Golden-task fixtures: input issue body + expected PR/comment shape. Optionally driven by a `gh` workflow. **Not pytest.** |
| `infra/` *(planned)* | Bicep | **UC1 output artefacts** — the Bicep modules the Spec Parser Agent assembles into a customer's landing-zone PR. Not infrastructure that hosts the agent. |
| `samples/` *(planned)* | JSON / Markdown | Sample WorkIQ specs, sample ADO PR payloads, sample drift reports — used as fixtures in golden tasks. |
| `docs/` *(exists)* | Markdown | Architecture, security, AI governance, ADRs, PRD, sprint plan. |
| `sprints/` *(exists)* | Markdown | Sprint backlogs S0–S6. |

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
1. Identify target scope (`agents/<name>/`, `infra/`, `docs/`, `.github/`, etc.).
2. Read docs in this order: target's local `AGENT.md` or `README.md` (if present) → `AGENTS.md` → this file → cross-cutting solution docs (`docs/*`).
3. Use the **MCP server allow-list** in `.github/copilot/mcp.json` to discover which tools are available. Never assume an MCP server exists — if it isn't in the allow-list, propose adding it via a separate PR with mandatory reviewer.
4. Implement minimal changes in the correct layer (`agents/<name>/` for prompt changes, `infra/` for UC1 Bicep outputs, `docs/` for governance).
5. Run the most specific golden-task fixture first, then broader ones, then propose updates to other fixtures if the change affects them.
6. Validate cross-cutting impact: prompts, MCP tool contracts in `AGENTS.md`, RBAC implied by new MCP usage, Bicep templates touched, security, docs.

### Scope Guards (mandatory)
- Changes in `agents/<name>/**`: read `agents/<name>/AGENT.md` and `AGENTS.md` first; if the change introduces a new MCP server or tool, also read `.github/copilot/mcp.json` and `docs/SECURITY.md`.
- Changes in `.github/copilot/mcp.json`: read `docs/SECURITY.md` and `docs/AI.md`; require CODEOWNERS approval; declare new server's required permissions in the PR.
- Changes in `infra/**`: read `docs/INFRASTRUCTURE.md` (which clarifies these are UC1 *outputs*) and `docs/ALM_PLAN.md` (Bicep validate workflow).
- Changes in `.github/workflows/**`: read `docs/ALM_PLAN.md` and `docs/SECURITY.md` (OIDC, secrets) before editing.
- Changes in `evals/**` / `agents/<name>/golden-tasks.md`: read `docs/AI.md` and `docs/TEST.md` first.
- Changes in `docs/**`: every edited doc must follow [§9 Document Versioning](#9-document-versioning).

### Key Technical Decisions
- **Runtime**: **GitHub Copilot coding agent** (per [ADR-0002](../docs/adr/0002-runtime-is-github-copilot-coding-agent.md)). No bespoke service, no Foundry-hosted agent. Agents are Markdown + MCP config + GitHub-native triggers (issues, `@copilot` mentions, `workflow_dispatch`, ADO Service Hook → issue, schedule → issue).
- **Model**: Whatever GitHub Copilot uses at runtime. The platform does not select, deploy, or manage a model.
- **Cloud**: Microsoft Azure for **agent targets only** (UC1's customer landing zones, UC2's scanned subscriptions, UC1's ADO Repos). No multi-cloud abstractions unless explicitly required.
- **IaC**: **Bicep** for all UC1 *output artefacts* (the landing-zone templates the Spec Parser Agent assembles). Use Terraform only when multi-cloud or an existing verified module mandates it.
- **Identity**:
  - **GitHub Copilot coding-agent identity** for everything that happens inside this repo.
  - **Managed Identity / Workload Identity Federation** for any Azure/ADO MCP call made by the coding agent. OBO when human-triggered.
  - No connection strings, no long-lived client secrets in code, config, or PR descriptions.
- **Secrets**: GitHub Actions secrets for CI; Azure Key Vault references *only inside Bicep modules under `infra/` (UC1 outputs)*, never for the platform itself.
- **Agent memory & traces**: The **repository itself** (issues, PRs, comments, branches, audit log) plus GitHub Copilot coding-agent run history. **No Cosmos DB persistence at the platform-runtime layer.** A Cosmos DB resource may appear *inside* a UC1-generated Bicep template when a customer landing zone requires it — that is an output, not a dependency.
- **Observability**: GitHub-native (issue/PR threads, audit log, Actions logs). No OpenTelemetry/Application Insights wiring required for the platform. A UC1-generated landing zone may include App Insights as an output — again, that is the customer's infra, not ours.
- **CI/CD**: GitHub Actions — markdown lint, Bicep build/validate (for any committed `infra/` template), CodeQL/secret scan. **OIDC federation** to Azure is used *only* when a workflow needs to do a `what-if` against a customer subscription on behalf of UC1 — not for deploying this platform.
- **Environments**: This platform has no `dev` / `test` / `prod` environments of its own. UC1's *output* landing zones have those environments; they are owned by the customer.

---

## 2. Build & Test Commands

> Commands below are the conventions for this repo. The platform itself has
> **no application build** — it is Markdown + Bicep + YAML. Commands are
> limited to lint, schema/Bicep validate, and golden-task fixture replay.

```bash
# Markdown lint (every doc edit must pass)
npx --yes markdownlint-cli2 "**/*.md" "#node_modules"

# Link check (catches broken cross-doc anchors when bumping versions)
npx --yes markdown-link-check docs/**/*.md sprints/*.md .github/*.md

# Bicep (UC1 output templates only)
az bicep build --file infra/main.bicep
# Dry-run against a customer subscription (UC1 staging deploy)
az deployment group what-if -g <rg> -f infra/main.bicep

# Golden-task replay (when evals/ exists; details in docs/TEST.md)
# Markdown-driven, not pytest. Example:
gh workflow run eval-goldens.yml -f agent=orchestrator -f fixture=smoke_echo
```

**There is no `pip install`, `npm test`, or `pytest` step in this repo.** If a
future use case introduces source code, it brings its own build/test commands
and updates this section in the same PR.

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
- Prefer **clarity over cleverness**. Markdown and Bicep should be readable by an on-call engineer.
- Validate inputs at trust boundaries (issue body schema for agent triggers, MCP tool input schemas).
- Fail fast with actionable error messages in agent prompts; instruct agents to refuse rather than guess.
- Add comments / prompt-internal rationale only to explain *why*, not *what*.

### Markdown (prompts, docs, agent definitions)
- Use ATX headings (`#`, `##`, ...), reference-style links, and fenced code blocks with language hints.
- All cross-doc links use repo-relative paths and pass `markdown-link-check`.
- Agent prompt files (`agents/<name>/AGENT.md`) use a fixed structure: **Identity**, **Scope**, **Tools**, **Refusal Rules**, **Output Contract**, **Confirmation Rules for `deploy`/`delete`**.
- Golden-task files (`agents/<name>/golden-tasks.md` or `evals/<name>/*.md`) use a fixed structure: **Input issue body**, **Expected MCP tool calls (ordered or set)**, **Expected PR/comment shape**, **Forbidden behaviors**.

### Bicep (UC1 output templates only)
- One module per resource type under `infra/modules/`; compose from `infra/main.bicep`.
- Parameterise environment (`dev` / `test` / `prod`) for the **customer's** landing zone; never hard-code names.
- Tag every resource: `env`, `owner`, `costCenter`, `workload`.
- Enable diagnostic settings → Log Analytics for every production resource the customer deploys.
- Run `az deployment ... what-if` before any `create`. UC1 prompts must require this step.

### Shell & PowerShell (only if a use case introduces helper scripts)
- Bash: `set -euo pipefail` at top of every script.
- PowerShell 7+: `Set-StrictMode -Version Latest` and `$ErrorActionPreference = 'Stop'`.

### Python / TypeScript (not present today)
- The platform contains no Python or TypeScript source. If a future PR introduces some, it must (a) bring linting/formatting/test config in the same PR, (b) document the new build/test commands in §2, and (c) reference an ADR explaining why a non-Markdown component is necessary.

### Agentic patterns (Copilot coding agent)
- Every agent **prompt file** declares: **name, owner, trigger(s), MCP servers in use, side-effect ceiling (`read | write | deploy | delete`), required permissions, golden-task path**.
- Every **MCP tool call** is treated as a typed call with explicit inputs/outputs; the agent must not improvise tool parameter shapes.
- Tools with side-effect ceiling `deploy` or `delete` require an **explicit human confirmation comment on the agent's draft PR or issue** before the agent fires the corresponding MCP call. The agent must produce a **dry-run / plan** first; the human approves; only then does the agent execute. This rule is enforced by per-agent prompts and called out in the PR template.
- Persist agent intent and outputs as **GitHub-native artefacts** (issues, PRs, comments, commits) so they are auditable without external infrastructure.
- Treat any value received from an MCP tool or LLM output as **untrusted input**: validate before passing to another tool, shell, or KQL query.
- Any prompt or agent-behavior change must be backed by an updated **golden-task fixture** in `agents/<name>/golden-tasks.md` (or `evals/<name>/`) referenced in the PR.

### GitHub Copilot coding-agent usage
- The Copilot coding agent picks up issues created via `ISSUE_TEMPLATE/` or `@copilot`-mentioned issues. It then opens a branch + draft PR.
- All MCP servers used by the agent must be listed in `.github/copilot/mcp.json` (allow-list). Changes to this file go through CODEOWNERS-approved PRs.
- Long-running tool calls (deploy, drift scan) must be split into a *plan* PR and a separate *apply* PR or follow-up comment; do not chain mutations behind one prompt.
- The agent must reference the relevant FR/NFR ID(s) from `docs/PRD.md` in its PR description (see §6).

---

## 4. Security

- Follow the **OWASP Top 10**; flag and fix vulnerable patterns on sight.
- **Authentication**:
  - The agent acts under **GitHub Copilot coding-agent identity** in this repo.
  - Outbound MCP calls into Azure / Azure DevOps use **Workload Identity Federation** (no long-lived secrets), and **OBO** when a human triggers the agent.
  - Entra ID is the IdP for human callers of MCP-targeted resources.
- **Secrets**:
  - Repository-level secrets via **GitHub Actions secrets** + **GitHub OIDC** — never long-lived in code, config, prompts, or PR descriptions.
  - Bicep templates under `infra/` (UC1 outputs) reference **Azure Key Vault** for the *customer's* landing zone; that Key Vault is provisioned by the template, not by this platform.
  - Agents must never echo, log, or commit secrets; agents must redact token-like strings before posting any comment.
- **MCP allow-list**: Only MCP servers listed in `.github/copilot/mcp.json` are permitted. Adding a server requires a CODEOWNERS-approved PR documenting purpose, required permissions, and a golden-task that exercises a representative tool.
- **RBAC**: Least privilege on every MCP-side principal (ADO PAT-equivalent scopes, Azure RBAC roles). Prefer built-in roles; scope at the resource or resource group level (never subscription unless required).
- **Tool inputs**: Validate and sanitise all MCP tool inputs at the prompt level. Treat any value derived from an LLM as untrusted.
- **Destructive actions**: deploy, delete, drop, force-push, scale-to-zero, and `terraform destroy` require an **explicit, separate human confirmation comment** on the agent's draft PR or issue. Do **not** auto-approve in any prompt or workflow.
- **Egress**: The platform itself has no egress (no service). UC1 *outputs* must use private endpoints for Key Vault, Cosmos DB, and Storage in production, and CORS allow-lists never `*`.

---

## 5. Testing Strategy

- **Fixture-first**: Every agent change must include or update a **golden-task fixture** under `agents/<name>/golden-tasks.md` (or `evals/<name>/`) that describes input issue body + expected MCP tool calls + expected PR/comment shape + forbidden behaviors.
- **Coverage target**: Every agent has at least one happy-path fixture and at least one failure-mode fixture before its sprint exits.
- **Bicep validation**: Every `.bicep` file under `infra/` must build cleanly (`az bicep build`) and pass `what-if` in CI when changed.
- **Markdown lint**: Every Markdown file must pass `markdownlint-cli2` and `markdown-link-check` in CI.
- **Eval harness**: Optional workflow `eval-goldens.yml` (planned) replays selected fixtures via the Copilot coding agent and asserts the PR/comment shape. There is **no `pytest` harness** in this repo.
- **All CI checks must pass** before merge. No flaky golden tasks — fix the prompt or pin the fixture.

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
- **Validation contract**: Required CI checks for affected components run
  green: markdown lint + link check on doc changes; `az bicep build` + `what-if`
  on `infra/**` changes; golden-task fixture replay on `agents/**` changes.
  PR includes command-level validation evidence (CI log link or pasted output).
- **Eval contract**: If a prompt under `agents/**` or a fixture under
  `evals/**` or `agents/**/golden-tasks.md` changed, the relevant golden
  task(s) were replayed and results attached.
- **Documentation contract**: Relevant docs are updated when behavior, contracts,
  security, or operations changed. If no doc update is required, PR states
  explicit justification.
- **Commit contract**: Commit messages follow Conventional Commits. Branch and
  PR are linked to the governing issue(s).
- **Traceability contract**: PR description lists every `FR-*` / `NFR-*` ID from
  `docs/PRD.md` it implements. If a new requirement is introduced or scope shifts,
  `docs/PRD.md` §7 (traceability matrix) is updated in the same PR. Golden-task
  fixtures reference the requirement ID(s) they verify (front-matter `requirement:`
  key, e.g. `requirement: FR-UC1-005`).
- **Versioning contract**: Any doc edited in the PR has its **Version** header
  bumped per the rules in [§9 Document Versioning](#9-document-versioning), and
  the **Previous Version** field is updated. If the PR makes no semantic change
  to a doc (e.g. pure formatting in a CI commit), the contract is satisfied by a
  PATCH bump.
- **Impact contract**: PR includes Bicep (UC1 output) impact, MCP allow-list
  impact, security impact, and eval impact statements. If impact is none, PR
  states `none` explicitly.
- **Review handoff contract**: PR lists residual risks/open questions and the
  agent summarises what should be reviewed first.

---

## 7. Code Review Checklist

Before approving a PR, verify:
- [ ] All CI checks pass (markdown lint, link check, Bicep build/validate where applicable, security scan, golden-task replay where applicable)
- [ ] New / changed agent prompts have at least one happy-path and one failure-mode golden-task fixture
- [ ] PR lists the `FR-*` / `NFR-*` IDs it implements; `docs/PRD.md` §7 is consistent
- [ ] Every edited doc has its **Version** header bumped per [§9 Document Versioning](#9-document-versioning)
- [ ] No hard-coded secrets, subscription IDs, tenant IDs, URLs, or resource names
- [ ] Any new MCP server is added to `.github/copilot/mcp.json` with documented purpose + required permissions, and a CODEOWNERS-approved review
- [ ] Agent prompts for `deploy`/`delete` side-effect tools enforce the human-confirmation comment rule
- [ ] Commit messages follow Conventional Commits format

### Change Impact Checklist (before merge)
- [ ] Documentation updated where behavior/contracts changed (`docs/*` or local `AGENT.md`)
- [ ] Security impact assessed (MCP allow-list, secrets, RBAC implied by new tool usage)
- [ ] Bicep (UC1 output) impact assessed (modules added/changed, `what-if` clean, tags applied)
- [ ] AI/eval impact assessed (golden-task replays, refusal-rule changes)

---

## 8. Naming Conventions

- **Files & folders**: lowercase with hyphens (`uc1-build-subscription.yml`, `drift-analyzer/`). Markdown files use `UPPER-SNAKE.md` only for top-level conventional docs (`AGENTS.md`, `README.md`, `SECURITY.md`); per-agent files inside a folder use lowercase (`agent.md`, `golden-tasks.md`, `runbook.md`).
- **Bicep resources**: `kebab-case` with environment suffix
  (e.g., `kv-agentic-devops-dev`, `cosmos-agentic-devops-prod`). These names appear in UC1 *output* templates; they are not the platform's own infrastructure.
- **Resource tags** (UC1 outputs): `env`, `owner`, `costCenter`, `workload` on every resource.
- **Git tags**: `vX.Y.Z` — managed by release tooling, never manual.
- **Agent names**: `kebab-case` matching the folder name (`spec-parser`, `pr-review`, `drift-analyzer`, `orchestrator`).
- **MCP server identifiers**: `kebab-case` matching the server's published name (`azure-mcp`, `azure-devops-mcp`, `github-mcp`, `workiq-mcp`).
- **Issue templates**: `uc<N>-<short>.yml` (e.g., `uc1-build-subscription.yml`).

---

## 9. Document Versioning

Every Markdown document in `docs/`, `sprints/`, `.github/`, and the root
`README.md` carries a version header (`Version`, `Date`, `Author`, `Status`,
`Previous Version`). Doc versions follow **[Semantic Versioning 2.0](https://semver.org/)**
adapted for prose:

| Bump | When | Examples |
|------|------|----------|
| **MAJOR** (`X.0.0`) | Breaking: rename/remove an identifier other docs depend on, reverse a previously-recorded decision, restructure headings so existing anchor links break, break a published contract. | Renaming `FR-UC1-005`; reversing SPRINT_PLAN §9 Q2; renaming a top-level section. |
| **MINOR** (`x.Y.0`) | Additive: new sections, new requirements, new stories, new decisions, refined wording that changes meaning but does not break IDs or anchors. | Adding the §9 decisions table; adding a new user story; adding a new FR/NFR row. |
| **PATCH** (`x.y.Z`) | Editorial: typos, formatting, link-target fixes, markdownlint fixes, tightening with no semantic change. | Fixing a typo; converting a 2-tuple version to a 3-tuple; reflowing a paragraph. |

### Rules
- Use the **three-component** form (`X.Y.Z`). Never `1.0` or `1`.
- Every PR that edits a doc must bump its `Version` and update `Previous Version`
  to the prior value (with a short parenthetical hint, e.g. `1.1.0 (added §7 matrix)`).
- Multiple bumps in a single PR collapse to **one** bump at the highest level
  applicable across the changes (e.g. an additive change plus typo fix = MINOR).
- A **MAJOR** bump must be backed by an ADR under `docs/adr/` explaining the
  break and migration path for any consumer that referenced the old IDs/anchors.
- The `Date` field is bumped only when the `Version` is bumped.
- Doc versions are **independent** from Git tag releases (`vX.Y.Z`). Git tags
  version the software; doc versions version the prose.
- ADRs (`docs/adr/NNNN-*.md`) use their `Status` field (Proposed → Accepted →
  Superseded) and do **not** require a SemVer header — supersession is recorded
  by linking the new ADR.
- When a previously-deferred decision becomes binding (e.g. SPRINT_PLAN §9 row
  reversed or refined), bump the document's MINOR (refinement) or MAJOR
  (reversal) and link to the superseding ADR.

### Examples in this repo
- Adding **§7 Traceability Matrix** to `docs/PRD.md` → MINOR (1.0.0 → 1.1.0).
- Adding `FR-PLT-007` after the matrix exists → another MINOR (1.1.0 → 1.2.0).
- Renaming `FR-UC1-005` → MAJOR (must add an ADR).
- Fixing a typo in a sprint header → PATCH (1.1.0 → 1.1.1).
