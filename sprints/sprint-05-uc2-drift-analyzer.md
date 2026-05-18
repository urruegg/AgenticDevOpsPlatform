# Sprint 5 — UC2 Drift Analyzer Agent

| Field | Value |
|-------|-------|
| **Version** | 2.1.0 |
| **Date** | 2026-05-25 |
| **Author** | Urs Rüegg |
| **Status** | Draft |
| **Previous Version** | 1.0.0 (initial release with Python `agents/drift_analyzer/`, `tools/azure_scan.py`, `tools/diff_engine.py`, `tools/ado_wiki_upsert.py`, `tools/teams_notify.py`, Azure Function Timer Trigger, Cosmos `drift-reports` + `tracked-subscriptions` containers, `agentic-devops` CLI subcommands); 1.0.1 clarified §6 dependency wording after WorkIQ moved to S2; 2.0.0 reframed the sprint around the **GitHub Copilot coding agent runtime** per [ADR-0002](../docs/adr/0002-runtime-is-github-copilot-coding-agent.md) via a §3.1 amendment overlay; 2.1.0 MINOR — removes the 1.x retained-for-traceability text and the §3.1 amendment overlay, rewriting §§3–5, 9 in final form. User-story IDs `S5-1..S5-7` preserved with reinterpreted acceptance criteria. |

> **Window**: 2026-07-20 → 2026-07-31 (2 weeks)
> **Theme**: Implement **UC2** — scheduled read-only Azure scans that compare
> live subscription state against the spec UC1 owns, produce a gap report, and
> route remediation back through UC1's deployment flow (and therefore UC3's
> review). Closes the virtuous cycle.

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
9. [Demo Script](#9-demo-script-m6)
10. [Related Documents](#10-related-documents)

---

## 1. Goal & Outcomes

A scheduled (nightly + on-demand) **Drift Analyzer Agent** scans tracked Azure
subscriptions in **read-only** mode via Azure MCP, compares them against the
canonical spec fetched from WorkIQ MCP, and produces a gap report. The SA
reviews the report; if a change is approved, remediation flows through UC1
(regenerate `.bicepparam`, staging deploy, ADO PR opened, UC3 reviews).

End-of-sprint capability:
- **Nightly**: `.github/workflows/uc2-nightly.yml` cron opens one drift-scan
  issue per tracked subscription from `.github/ISSUE_TEMPLATE/uc2-drift-scan.yml`.
- **On-demand**: SA files the same issue manually.
- The Copilot coding agent picks up the issue, runs the read-only scan via
  Azure MCP, diffs against the WorkIQ spec, writes the gap report as the
  issue body + a structured comment, upserts the customer's ADO Wiki page
  `/Drift/<subscriptionId>` via Azure DevOps MCP, and (for `severity:error`)
  triggers a Teams notification via a GitHub Actions step + webhook secret.

---

## 2. Use Cases Addressed

- **UC2 — Subscription Updates (Drift & Change Management)**

```mermaid
sequenceDiagram
    autonumber
    actor SA
    participant GH as GitHub (issue + PR)
    participant Cop as Copilot coding agent<br/>(agents/drift-analyzer/AGENT.md)
    participant Az as Azure MCP (read-only)
    participant WIQ as WorkIQ MCP
    participant ADO as Azure DevOps MCP
    participant Teams as Teams (webhook)

    Note over GH: uc2-nightly.yml cron OR<br/>SA files uc2-drift-scan.yml issue
    GH->>Cop: invoke (one issue per tracked sub)
    Cop->>Az: enumerate RGs + resource configs (Reader)
    Cop->>WIQ: fetch canonical spec
    Cop->>Cop: diff actual vs spec; assign severities
    Cop-->>GH: drift report (issue body + structured comment)
    Cop->>ADO: upsert /Drift/<subId> wiki page
    alt severity:error present
        GH->>Teams: notify subscription owner
    end
    SA->>GH: file UC1 remediation issue (manual decision)
    Note over GH: UC1 chain → ADO PR → UC3 review
```

---

## 3. Scope

### In Scope
- `agents/drift-analyzer/AGENT.md` — Identity, Scope, Tools (Azure MCP read tools, WorkIQ MCP, Azure DevOps MCP wiki-upsert), Refusal Rules (no Azure write, no UC1 trigger without SA-filed issue), Output Contract (issue body + structured comment + ADO Wiki Markdown).
- `agents/drift-analyzer/golden-tasks.md` — 4 fixtures: clean (no drift), tag drift, missing resource, extra unsanctioned resource.
- `.github/workflows/uc2-nightly.yml` — cron-triggered GitHub Actions workflow (default `0 2 * * *` UTC) that reads `samples/tracked-subscriptions.md`, opens one drift-scan issue per row using `.github/ISSUE_TEMPLATE/uc2-drift-scan.yml`. Missed runs are retried on next cron tick (idempotent by `scanDate + subscriptionId` label).
- `.github/ISSUE_TEMPLATE/uc2-drift-scan.yml` — on-demand trigger (same path as nightly).
- `.github/ISSUE_TEMPLATE/uc2-track-subscription.yml` — issue template requesting a new tracked subscription; the agent opens a PR to `samples/tracked-subscriptions.md` adding/removing the row.
- `samples/tracked-subscriptions.md` — the registry. One row per subscription: `subscriptionId`, `tenantId`, `specRef` (WorkIQ link), `owner`, `severityOverrides`. CRUD via PR.
- `.github/copilot/mcp.json` — `azure-mcp` configured with a `Reader`-scoped service principal federated via WIF (per-subscription scope, not subscription-wide); `azure-devops-mcp` scoped to `Wiki (R/W)` only for this agent; `workiq-mcp` read scope.
- Severity rules encoded in `agents/drift-analyzer/AGENT.md`: missing required tag = `error`; extra unsanctioned resource = `warn`; drifted SKU on non-prod = `info`. Output sorted by `resourcePath` then `property` for stable diff between runs.
- Teams notification implemented as a GitHub Actions step in `uc2-nightly.yml` that fires only when the issue carries `severity:error` (label applied by the agent). Webhook stored in GitHub Actions secrets.
- `AGENTS.md` updated: `drift-analyzer` row with trigger, MCP servers, side-effect ceiling (`write` — issues + ADO wiki only; UC1 remediation routed through human-filed issues).

### Out of Scope
- Auto-remediation (intentional — humans in the loop per governance).
- Cross-subscription / management-group rollups (later).
- Non-Azure cloud scans (out of platform scope).
- Any platform Cosmos / Function timer / App Insights wiring — per [ADR-0002](../docs/adr/0002-runtime-is-github-copilot-coding-agent.md) the platform owns no Azure infrastructure.

---

## 4. User Stories & Acceptance Criteria

### S5-1 — Tracked-subscription registry (Markdown)
**As a** platform owner
**I want** a registry of tracked subscriptions and their canonical specs
**so that** the agent knows what to scan and what to compare against.

**Acceptance**:
- [ ] `samples/tracked-subscriptions.md` lists one row per subscription with: `subscriptionId`, `tenantId`, `specRef` (WorkIQ link/ID), `owner`, `severityOverrides` (optional inline JSON).
- [ ] Add/remove flows via `.github/ISSUE_TEMPLATE/uc2-track-subscription.yml` → the agent opens a PR editing the file.
- [ ] PRs to this file are CODEOWNERS-gated (platform owners).
- [ ] *Implements*: `FR-UC2-001`.

### S5-2 — Read-only Azure scan via Azure MCP
**As an** auditor
**I want** the agent to scan all resources and key properties in a subscription
**so that** drift detection is comprehensive.

**Acceptance**:
- [ ] `agents/drift-analyzer/AGENT.md` declares Azure MCP read tools with side-effect ceiling `read`. Refusal rule blocks any `write`/`deploy`/`delete` tool call.
- [ ] Scan covers resource groups, VNETs/subnets, NSGs, storage accounts, key vaults, app services, function apps (configurable in the prompt per resource type).
- [ ] Service principal scoped to `Reader` (+ `Reader and Data Access` where required) on each tracked subscription. Verified by negative-path golden task: write attempts return 403.
- [ ] Scan completes for a 200-resource subscription in < 5 min.
- [ ] *Implements*: `FR-UC2-002`, `NFR-SEC-001`.

### S5-3 — Diff engine with severities (stable ordering)
**Acceptance**:
- [ ] Agent emits a list of `{resourcePath, property, expected, actual, severity}` items rendered as a Markdown table in the issue body.
- [ ] Severity rules: missing required tag = `error`; extra unsanctioned resource = `warn`; drifted SKU on non-prod = `info`.
- [ ] Output sorted by `resourcePath` then `property` so repeat reports diff cleanly between runs (asserted by golden-task fixture).
- [ ] `severityOverrides` from the registry row are honoured.
- [ ] *Implements*: `FR-UC2-003`, `FR-UC2-004`.

### S5-4 — Report sinks (issue + ADO Wiki + Teams)
**Acceptance**:
- [ ] Drift report posted to the drift-scan issue body (high-level) plus a structured comment carrying the detailed Markdown table. The issue is the persistent artefact; long-term history is the Git log of the customer's ADO Wiki page.
- [ ] Agent calls Azure DevOps MCP `wiki-upsert` to upsert the customer ADO Wiki page at `/Drift/<subscriptionId>` with the same Markdown table. Side-effect ceiling `write`.
- [ ] When the report contains `severity:error` items, the agent applies the `severity:error` label on the issue; the `uc2-nightly.yml` follow-up step posts to a Teams channel via a webhook secret.
- [ ] Zero-drift runs: agent posts a one-line "no drift" comment, applies `severity:none`, no Teams ping.
- [ ] *Implements*: `FR-UC2-005`, `NFR-OPS-001`.

### S5-5 — Scheduler + on-demand trigger
**Acceptance**:
- [ ] `.github/workflows/uc2-nightly.yml` runs on `cron: '0 2 * * *'` UTC. Reads `samples/tracked-subscriptions.md`; opens one issue per row from `uc2-drift-scan.yml`.
- [ ] Idempotency: workflow labels each issue with `uc2-scan-<yyyy-mm-dd>-<subId>`; a re-run within the same UTC day skips already-labelled issues.
- [ ] On-demand: an SA can file the issue manually for the same outcome; the agent does not de-dupe against the manual issue (a manual scan is always intentional).
- [ ] Workflow logs run history; failed runs surface a workflow-failure issue.
- [ ] *Implements*: `FR-UC2-006`, `NFR-OPS-003`.

### S5-6 — Remediation routed through UC1
**As an** SA
**I want** to accept the drift report and trigger UC1 with the latest spec
**so that** changes follow the standard review path.

**Acceptance**:
- [ ] Agent's drift report includes a "Remediate via UC1" section showing the WorkIQ spec link and a copy-paste-ready issue body for `.github/ISSUE_TEMPLATE/uc1-build-subscription.yml`.
- [ ] The drift agent **never** triggers UC1 automatically. The SA decides and files a new UC1 issue.
- [ ] No drift-induced changes deploy without going through UC1's staging + ADO PR + UC3 review cycle (refusal rule enforced).
- [ ] *Implements*: `FR-UC2-007`, `NFR-GOV-002`.

### S5-7 — Golden tasks
**Acceptance**:
- [ ] 4 fixtures in `agents/drift-analyzer/golden-tasks.md`: clean (no drift), tag-drift, missing-resource, extra-unsanctioned-resource.
- [ ] Each fixture has `requirement:` front-matter listing FR/NFR IDs.
- [ ] Replay via `eval-goldens.yml` (or manual) — pass rate ≥ 95 %.
- [ ] *Implements*: `NFR-GOV-006`, `FR-PLT-003`.

---

## 5. Deliverables

| Artifact | Path |
|----------|------|
| Drift Analyzer prompt | `agents/drift-analyzer/AGENT.md` |
| Golden tasks | `agents/drift-analyzer/golden-tasks.md` |
| Nightly scheduler | `.github/workflows/uc2-nightly.yml` |
| Issue templates | `.github/ISSUE_TEMPLATE/uc2-drift-scan.yml`, `.github/ISSUE_TEMPLATE/uc2-track-subscription.yml` |
| Tracked-subscription registry | `samples/tracked-subscriptions.md` |
| MCP allow-list update | `.github/copilot/mcp.json` (`azure-mcp` Reader-scoped; `azure-devops-mcp` Wiki-scoped for this agent; `workiq-mcp` read) |
| Agent registry | `AGENTS.md` (drift-analyzer row) |
| Runbook | `docs/runbooks/uc2-drift.md` |

---

## 6. Dependencies

- [Sprint 3](./sprint-03-uc1-end-to-end.md) complete — WorkIQ MCP, OBO, full UC1 deployment flow.
- [Sprint 4](./sprint-04-uc3-pr-review-agent.md) complete — UC3 will review any drift-driven ADO PRs.
- At least one tracked subscription with a known canonical spec (the staging subscription from Sprints 2/3 is the natural fixture).

---

## 7. Risks & Mitigations

| Risk | Mitigation |
|------|------------|
| Read-only scope leaks (agent over-permitted) | `Reader` role pinned in the MCP service principal; negative-path golden task asserts write refusal; quarterly access review documented in runbook. |
| Scan exceeds workflow timeout | Fan-out: nightly workflow opens one issue per subscription; per-subscription scans run in parallel via the agent's run history (no single job covers many subscriptions). |
| Noisy reports cause alert fatigue | Severity tiers + only `severity:error` triggers Teams notification; weekly digest for `warn`/`info`. |
| Spec drift ≠ deployed reality (spec is wrong) | Drift report's "Remediate via UC1" section explicitly offers both directions: accept reality (update spec in WorkIQ + new UC1 issue) or fix the subscription (UC1 issue with current spec). |
| Idempotency gap in nightly cron | Per-day issue label gate; failed runs surface a workflow-failure issue rather than retry blindly. |

---

## 8. Exit Criteria

- [ ] All user stories done.
- [ ] M6 demo executed.
- [ ] Nightly scan green for 5 consecutive runs.
- [ ] All 4 golden-task fixtures pass (≥ 95 %).
- [ ] Negative-path golden task: agent identity write attempt returns 403.

---

## 9. Demo Script (M6)

1. Open a PR adding the staging subscription to `samples/tracked-subscriptions.md` via the `uc2-track-subscription.yml` issue → review → merge.
2. Manually tweak a tag on a storage account in the tracked subscription (introduce drift).
3. Manually trigger `.github/workflows/uc2-nightly.yml` (`workflow_dispatch`) — or file the `uc2-drift-scan.yml` issue directly.
4. Watch the Copilot coding agent process the drift-scan issue: scan via Azure MCP → diff against WorkIQ spec → post Markdown drift table to the issue body + structured comment, apply `severity:error` label, upsert the customer's ADO Wiki page `/Drift/<subscriptionId>`, fire the Teams webhook step.
5. SA opens a UC1 remediation issue using the copy-paste block from the drift report → UC1 chain fires → ADO PR opened → UC3 (Sprint 4) reviews automatically → full virtuous cycle.
6. Show the negative path: agent identity attempts a write via Azure MCP → 403 (golden task).

---

## 10. Related Documents

- [sprints/SPRINT_PLAN.md](./SPRINT_PLAN.md)
- [sprints/sprint-03-uc1-end-to-end.md](./sprint-03-uc1-end-to-end.md)
- [sprints/sprint-04-uc3-pr-review-agent.md](./sprint-04-uc3-pr-review-agent.md)
- [docs/SOLUTION_OVERVIEW.md §5.2](../docs/SOLUTION_OVERVIEW.md#52-use-case-2--subscription-updates-drift--change-management)
- [docs/DATA.md](../docs/DATA.md)
