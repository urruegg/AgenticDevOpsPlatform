# Application Lifecycle Management (ALM) Plan

| Field | Value |
|-------|-------|
| **Version** | 1.0 |
| **Date** | 2026-05-18 |
| **Author** | Urs Rüegg |
| **Status** | Draft |
| **Previous Version** | — (initial release) |

> **Related**: [INFRASTRUCTURE.md](INFRASTRUCTURE.md), [SECURITY.md](SECURITY.md),
> [TEST.md](TEST.md).

## Table of Contents

1. [Branching & Release Model](#1-branching--release-model)
2. [CI/CD Pipelines](#2-cicd-pipelines)
3. [Authentication to Azure](#3-authentication-to-azure)
4. [Environments & Approvals](#4-environments--approvals)
5. [Quality Gates](#5-quality-gates)
6. [Release Notes](#6-release-notes)
7. [Rollback Strategy](#7-rollback-strategy)
8. [Observability After Deploy](#8-observability-after-deploy)
9. [Open Questions](#9-open-questions)

## 1. Branching & Release Model
- **Single-branch model**: all work lands on `main`.
- Copilot coding agent and contributors create feature branches automatically
  from issues.
- **Conventional Commits** drive semantic release on merge.
- No release branches; tags are managed by release tooling — never manually.

## 2. CI/CD Pipelines

### 2.1 Pipeline Stages
```
lint → unit-test → build → security-scan → IaC-validate → eval → deploy
```

### 2.2 Workflows (planned, under `.github/workflows/`)

| Workflow | Trigger | Purpose |
|----------|---------|---------|
| `ci.yml` | PR + push to `main` | Lint, unit tests, build, coverage |
| `iac-validate.yml` | PR touching `infra/**` | Bicep build + `what-if` dry-run |
| `security.yml` | PR + nightly | CodeQL, dependency scan, secret scan |
| `eval.yml` | PR touching `agents/**`, `tools/**`, `evals/**` + nightly | Agent eval harness |
| `deploy-dev.yml` | Merge to `main` | Deploy infra + agents to `dev` |
| `deploy-test.yml` | Manual dispatch | Deploy to `test` |
| `deploy-prod.yml` | Manual dispatch + approval | Deploy to `prod` |

## 3. Authentication to Azure
- **OIDC federation** (no long-lived secrets in GitHub).
- Federated credentials per environment:
  - `repo:<owner>/AgenticDevOpsPlatform:environment:dev`
  - `repo:<owner>/AgenticDevOpsPlatform:environment:test`
  - `repo:<owner>/AgenticDevOpsPlatform:environment:prod`
- Each environment maps to its own service principal with **least-privilege**
  RBAC on the corresponding resource group.

## 4. Environments & Approvals

| Environment | Auto-Deploy | Approvers |
|-------------|-------------|-----------|
| `dev` | Yes (on merge to `main`) | — |
| `test` | Manual dispatch | Eng lead |
| `prod` | Manual dispatch with required reviewer | Platform owner + Security |

## 5. Quality Gates
- Lint and unit tests must pass.
- Coverage ≥ 80 % on changed files.
- IaC `what-if` must show no unintended drift.
- Security scan: no new high/critical findings.
- Eval harness: no regression vs. previous baseline (threshold TBD).

## 6. Release Notes
- Generated automatically from Conventional Commits.
- Published as GitHub Releases tied to `vX.Y.Z` tags.

## 7. Rollback Strategy
- **Code**: revert PR and redeploy.
- **Infra**: redeploy previous Bicep parameter set (versioned in repo).
- **Agents**: prompt and tool registry are versioned; rollback by pinning the
  prior version in the agent runtime config.

## 8. Observability After Deploy
- Smoke-tests run after every deploy.
- Application Insights alerts on error-rate / latency regression.
- Eval harness scheduled run within 1 hour of prod deploy.

## 9. Open Questions
- TBD
