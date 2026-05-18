# Application Lifecycle Management (ALM) Plan

| Field | Value |
|-------|-------|
| **Version** | 2.0.0 |
| **Date** | 2026-05-18 |
| **Author** | Urs Rüegg |
| **Status** | Draft |
| **Previous Version** | 1.0.0 (per-env `deploy-dev/test/prod.yml`, lint→unit-test→build→security-scan→IaC-validate→eval→deploy pipeline for a hosted runtime); 2.0.0 retires the platform-deploy stages per [ADR-0002](adr/0002-runtime-is-github-copilot-coding-agent.md) — no platform runtime to deploy. CI now centres on markdown lint, link check, Bicep validate for UC1 outputs, and security scans. Per-customer deploys of UC1 outputs are owned by the customer's pipeline. |

> **Related**: [ADR-0002](adr/0002-runtime-is-github-copilot-coding-agent.md),
> [INFRASTRUCTURE.md](INFRASTRUCTURE.md), [SECURITY.md](SECURITY.md),
> [TEST.md](TEST.md).

## Table of Contents

1. [Branching & Release Model](#1-branching--release-model)
2. [CI Pipelines](#2-ci-pipelines)
3. [Authentication to Azure (UC1 only)](#3-authentication-to-azure-uc1-only)
4. [UC1 Customer Deploys (out of scope for this repo)](#4-uc1-customer-deploys-out-of-scope-for-this-repo)
5. [Quality Gates](#5-quality-gates)
6. [Release Notes](#6-release-notes)
7. [Rollback Strategy](#7-rollback-strategy)
8. [Observability After Deploy](#8-observability-after-deploy)
9. [Open Questions](#9-open-questions)

## 1. Branching & Release Model
- **Single-branch model**: all work lands on `main`.
- GitHub Copilot coding agent and contributors create feature branches automatically
  from issues.
- **Conventional Commits** drive semantic release on merge.
- No release branches; tags are managed by release tooling — never manually.
- The repo has no application binary to release. Tags mark **doc/template
  library** versions used by UC1 prompts.

## 2. CI Pipelines

The platform has **no application build and no deploy**. CI focuses on
Markdown hygiene, Bicep validation (for UC1 output templates), security,
and optional golden-task replay.

### 2.1 Pipeline Stages
```
markdown-lint → link-check → bicep-validate (if infra/** touched) → security-scan → (optional) eval-goldens
```

### 2.2 Workflows (planned, under `.github/workflows/`)

| Workflow | Trigger | Purpose |
|----------|---------|---------|
| `ci.yml` | PR + push to `main` | `markdownlint-cli2`, `markdown-link-check`, repo conventions check |
| `iac-validate.yml` | PR touching `infra/**` | `az bicep build` + `az deployment ... what-if` against a customer sandbox via OIDC; result attached to the PR |
| `security.yml` | PR + nightly | CodeQL, dependency scan, secret scan |
| `eval-goldens.yml` *(optional)* | PR touching `agents/**`, `.github/copilot/**`, `evals/**` + manual dispatch | Replays selected golden-task fixtures against the Copilot coding agent and posts results |
| `uc2-nightly.yml` | Schedule (cron) | Opens an issue for the Drift Analyzer Agent per tracked subscription (UC2 trigger) |
| `uc3-webhook-receiver.yml` *(planned)* | `repository_dispatch` from ADO Service Hook | Authenticates the inbound event, then files an issue for the PR Review Agent (UC3 trigger) |

There are **no** `deploy-dev.yml` / `deploy-test.yml` / `deploy-prod.yml`
workflows because the platform has no environments of its own to deploy to.
If UC1's *output* customer-side pipeline needs reusable building blocks,
those are templates inside `infra/`, not platform workflows.

## 3. Authentication to Azure (UC1 only)

The only platform workflows that touch Azure are `iac-validate.yml` (for
`what-if` against a customer sandbox) and any helper UC1 workflows.

- **OIDC federation** to a customer-side service principal (no long-lived
  secrets in GitHub).
- Federated credentials are scoped per **customer environment**, not per
  platform environment:
  - `repo:<owner>/AgenticDevOpsPlatform:environment:<customer>-sandbox`
  - `repo:<owner>/AgenticDevOpsPlatform:environment:<customer>-prod`
- Each environment maps to a customer-side SP with least-privilege RBAC on
  the relevant resource group. UC1's PR description must list the exact
  RBAC scopes required.

## 4. UC1 Customer Deploys (out of scope for this repo)

The staging / prod deploy of a customer's landing zone is executed by **the
customer's ADO Pipeline** (kicked off by the agent's PR via Azure DevOps
MCP). The pipeline definition itself is a UC1 output committed to the
customer's ADO Repo; it is *not* a workflow under this platform's
`.github/workflows/`.

Approval gates, environment-specific reviewers, smoke tests, and rollback
for the customer's landing zone are configured in the customer's ADO
Environments, not here.

## 5. Quality Gates

For any PR against this repo:
- `markdown-lint` and `markdown-link-check` must pass.
- If `infra/**` changes: `az bicep build` and a `what-if` against the
  customer sandbox must succeed.
- `security.yml`: no new high/critical findings.
- If `agents/**` / `.github/copilot/**` / `evals/**` changes: the relevant
  golden-task replay must show no regression vs. the baseline (threshold
  documented in [TEST.md](TEST.md)).
- All doc edits must comply with the SemVer policy in
  [`/.github/copilot-instructions.md` §9](../.github/copilot-instructions.md#9-document-versioning).

## 6. Release Notes
- Generated automatically from Conventional Commits on merge to `main`.
- Published as GitHub Releases tied to `vX.Y.Z` tags. Tags here mark the
  state of the **doc + template + prompt library**, not a service.

## 7. Rollback Strategy
- **Repo content (prompts, AGENTS.md, MCP allow-list, Bicep templates)**:
  revert the PR and let the next agent run pick up the previous state.
- **UC1 customer deploys**: rolled back by the customer's pipeline using
  the previous Bicep parameter set (versioned in their ADO Repo). The
  agent only produces the PR; rollback is owned by the customer.
- **Agent prompts**: pinned by Git history; rolling back is a revert.
  The Copilot coding agent picks up the reverted state on its next run.

## 8. Observability After Deploy
- **Repo / agent**: GitHub audit log + Copilot run history + GitHub Actions
  logs. There is no "after-deploy" smoke test workflow for the platform.
- **UC1 customer landing zone**: smoke tests live in the customer's ADO
  pipeline; alerts in the customer's App Insights / Log Analytics.

## 9. Open Questions
- Final shape of `uc3-webhook-receiver.yml` (HMAC validation, IP allowlist,
  short-lived token from ADO). Resolved in Sprint 4.
- Whether to mirror UC1 PRs into a customer-specific GitHub repo for
  cross-system traceability. Deferred until pilot.

