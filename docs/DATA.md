# Data Model & Storage

| Field | Value |
|-------|-------|
| **Version** | 2.0.0 |
| **Date** | 2026-05-18 |
| **Author** | Urs Rüegg |
| **Status** | Draft |
| **Previous Version** | 1.0.0 (Cosmos DB as primary platform store with `agent-runs`, `agent-sessions`, `drift-reports`, `policy-cache` containers and OpenTelemetry trace schema); 2.0.0 retires that model per [ADR-0002](adr/0002-runtime-is-github-copilot-coding-agent.md). The repository itself (issues, PRs, comments, branches, audit log) is now the agent memory. Cosmos DB can still appear *inside* a UC1-generated landing zone, but only as an output that the customer owns. |

> **Related**: [ADR-0002](adr/0002-runtime-is-github-copilot-coding-agent.md),
> [ARCHITECTURE.md](ARCHITECTURE.md), [SECURITY.md](SECURITY.md).

## Table of Contents

1. [Platform Data Inventory](#1-platform-data-inventory)
2. [Agent Memory & Traces](#2-agent-memory--traces)
3. [UC2 Drift Reports](#3-uc2-drift-reports)
4. [UC1 Output Stores (customer-owned)](#4-uc1-output-stores-customer-owned)
5. [Retention & PII](#5-retention--pii)
6. [Open Questions](#6-open-questions)

## 1. Platform Data Inventory

The platform itself owns no operational database. Everything the agent
produces or relies on is either a repository asset, a GitHub-managed
artefact, or lives on the *target* side (ADO, Azure, M365).

| Data Set | Source | Store | Sensitivity | Retention |
|----------|--------|-------|-------------|-----------|
| Subscription / landing-zone spec | M365 / SharePoint / OneDrive (Excel/JSON) | Read-only via WorkIQ MCP | Internal | N/A (source of truth lives in M365) |
| Bicep template library (UC1 *output*) | Repository | This repo at `infra/**` | Internal | Indefinite (Git history) |
| Agent prompt files | Repository | This repo at `agents/<name>/AGENT.md` | Internal | Indefinite (Git history) |
| Golden-task fixtures | Repository | This repo at `agents/<name>/golden-tasks.md` (and/or `evals/**`) | Internal | Indefinite (Git history) |
| `AGENTS.md` registry | Repository | This repo at root | Internal | Indefinite (Git history) |
| MCP allow-list | Repository | This repo at `.github/copilot/mcp.json` | Internal | Indefinite (Git history) |
| Issue body (agent input) | Human / scheduler / webhook | GitHub issue | Internal | Per GitHub retention |
| Agent run history | GitHub Copilot coding agent | GitHub UI + audit log | Internal | Per GitHub retention |
| Draft PR + branch + commits | GitHub Copilot coding agent | This repo / linked repos | Internal | Indefinite (Git history) |
| PR comments (UC3 outputs) | PR Review Agent via Azure DevOps MCP | ADO PR thread | Internal | Per ADO retention |
| Pipeline logs (UC1 staging deploy) | ADO Pipelines | ADO + customer Log Analytics | Internal | Per customer policy |
| Drift reports (UC2) | Drift Analyzer Agent | ADO Wiki at `/Drift/<subscriptionId>` + remediation issue in this repo | Internal | Per ADO Wiki policy + 365 days remediation issue label |

## 2. Agent Memory & Traces

**Short-term memory** is in-prompt context.

**Long-term memory and trace** is the **repository itself plus GitHub
Copilot coding-agent run history**:

- The originating issue (agent input).
- The Copilot agent's run timeline (visible in GitHub UI).
- The branch + commit history the agent produced.
- The draft PR (description, files changed, conversation thread).
- The audit-log entries for any sensitive operation.

This design satisfies the PRD's audit/replay intent (see
[`docs/PRD.md` FR-PLT-004 / FR-PLT-005](PRD.md#44-platform--cross-cutting-fr-plt-))
without an OpenTelemetry pipeline or a Cosmos DB run document.

If a future PRD update demands richer telemetry (e.g., aggregated
p95 latency across agents), it can be layered on top by:

- exporting the GitHub audit log + Copilot run history into a customer-owned
  Log Analytics workspace via a workflow, **or**
- adding an opt-in MCP tool that writes structured run summaries to a
  customer-owned store.

Neither is required to ship UC1/UC2/UC3.

## 3. UC2 Drift Reports

Drift reports live where humans can find them on the customer side:

- **ADO Wiki** at `/Drift/<subscriptionId>` — latest report per
  subscription, upserted on each scan (per [FR-UC2-007](PRD.md#42-uc2--drift-detection-fr-uc2-)).
- **GitHub issue** in this repo (label `uc2-drift-scan`) — the trigger
  artefact filed by the nightly schedule workflow; closed when the
  remediation PR merges in UC1.
- **GitHub PR** (when the SA chooses `fix-to-spec`) — opened by the UC1
  Spec Parser Agent via Azure DevOps MCP against the customer's ADO Repo.

No Cosmos DB persistence at the platform layer. Retention of the ADO Wiki
entry is governed by ADO's wiki retention. A future enhancement may snapshot
drift reports to a customer-owned Storage Account; that would be an
*output* of UC1, not a platform dependency.

## 4. UC1 Output Stores (customer-owned)

When UC1 produces a landing-zone template, the generated Bicep may include
data services for the customer's workload:

- **Azure Cosmos DB (NoSQL)** — if the landing zone hosts an application
  that needs partitioned NoSQL storage. The Bicep module enforces partition
  keys, HPK where appropriate, RBAC, private endpoints, and continuous
  backup in `prod`.
- **Azure Key Vault** — for the *customer's* application secrets.
- **Azure Storage** — for artefacts the customer's workload needs.

These resources are part of the customer's environment, not the platform.
When they appear in a Bicep module under `infra/`, the partitioning,
retention, and access rules in the prior v1.0.0 of this doc apply to *them*,
not to platform memory.

## 5. Retention & PII

- **PII**: Agents must redact PII before posting any comment or commit
  (also a SECURITY.md and `AGENTS.md` rule). Issue bodies that contain PII
  must be edited out by the agent before further processing.
- **Default retention**:
  - Repo content: indefinite (Git history).
  - GitHub issues / PRs / audit log: per GitHub retention policy.
  - ADO PR comments and Wiki entries: per ADO retention policy.
- **Right to erasure**: handled by editing or deleting the offending
  issue/PR/comment in GitHub or ADO. Agents do not store personal data
  outside those surfaces.

## 6. Open Questions

- Whether to add a long-term telemetry export (audit log → Log Analytics)
  for the platform itself. Currently deferred until a use case requires it.

