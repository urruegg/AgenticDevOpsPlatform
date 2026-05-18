# Sprint 3 — UC1 End-to-End + Excel + Policy + PR

| Field | Value |
|-------|-------|
| **Version** | 2.1.0 |
| **Date** | 2026-05-25 |
| **Author** | Urs Rüegg |
| **Status** | Draft |
| **Previous Version** | 1.0.0 (introduced WorkIQ in S3); 1.1.0 re-scoped to Excel + Policy + PR (WorkIQ moved to S2 — Python `tools/excel_to_spec.py`, `tools/ado_branch.py`, `tools/ado_commit.py`, `tools/ado_pr_open.py`, `agents/auth/obo.py`, `pytest` evals); 2.0.0 reframed the sprint around the **GitHub Copilot coding agent runtime** per [ADR-0002](../docs/adr/0002-runtime-is-github-copilot-coding-agent.md) via a §3.1 amendment overlay; 2.1.0 MINOR — removes the 1.x retained-for-traceability text and the §3.1 amendment overlay, rewriting §§3–5, 9 in final form. User-story IDs `S3-1..S3-6` preserved with reinterpreted acceptance criteria. |

> **Window**: 2026-06-22 → 2026-07-03 (2 weeks)
> **Theme**: Close out **UC1** — extend WorkIQ MCP (introduced in [Sprint 2](./sprint-02-uc1-spec-parser-happy-path.md))
> to cover **Excel specs**, enforce **Azure Policy** on staging, switch the
> agent to **OBO authentication**, and open a real **PR in ADO** with the
> validation report attached. Marks **end of roadmap Phase 1 (Prototype)**.

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
9. [Demo Script](#9-demo-script-m4)
10. [Related Documents](#10-related-documents)

---

## 1. Goal & Outcomes

Make UC1 **production-shaped**: building on the WorkIQ MCP integration from
[Sprint 2](./sprint-02-uc1-spec-parser-happy-path.md), the SA can now point
at a spec stored as **Excel** in SharePoint (the WorkIQ MCP server handles
the `.xlsx` → JSON mapping; the agent only validates JSON). After the
staging deployment, the agent commits the generated files to a feature
branch in the customer's ADO Repo via Azure DevOps MCP and opens a real
**ADO Pull Request** with the validation report attached. Identity moves
from a service principal to **OBO** at the MCP server layer.

End-of-sprint capability: SA files a UC1 issue with a SharePoint URL → the
Copilot coding agent fetches via WorkIQ MCP (JSON or Excel — the MCP server
does the mapping) → posts the deployment plan on a GitHub draft PR → SA
replies `approved-to-apply` → staging deploys → agent commits + opens an
ADO PR with the validation report attached → full audit trail under the
SA's OBO identity.

---

## 2. Use Cases Addressed

- **UC1 — Initial Azure Subscription Build** (end-to-end with WorkIQ Excel + Azure Policy + ADO PR)

---

## 3. Scope

### In Scope
- **WorkIQ MCP Excel happy path**: the WorkIQ MCP server returns the spec as JSON regardless of whether the source is `.xlsx` or already JSON. The agent treats Excel handling as a transparent property of the MCP server (no `.xlsx` parsing in this repo).
- **Azure DevOps MCP write path** (promote from read-only in Sprint 2): create branch, commit files, open PR. Side-effect ceiling for "open PR" is `write`. Side-effect ceiling for "trigger pipeline" remains `deploy` (gated by `approved-to-apply`).
- **ADO PR template** at `samples/azuredevops/pull_request_template.md` — committed to the customer's ADO Repo by the agent as part of the UC1 output. Auto-populated with validation report + agent-run link.
- **Azure Policy initiative** attached to the staging subscription enforcing required tags (`env`, `owner`, `costCenter`, `workload`), allowed locations, no public IPs on storage. Implemented as a UC1 *output* Bicep module under `infra/landing-zone/policy/`.
- **OBO authentication** at the MCP layer: when an issue is filed by a human, the WorkIQ MCP server and Azure DevOps MCP server act on behalf of the SA, not as a service principal. The Copilot coding agent passes the human's identity through. No OBO code lives in this repo.
- **Expanded golden tasks** in `agents/spec-parser/golden-tasks.md`: 6+ fixtures incl. happy-path JSON, SharePoint URL with Excel source, missing-tag, policy-violation, ADO-unreachable.
- **Runbook** `docs/runbooks/uc1-build-subscription.md` documenting prerequisites, the issue template flow, expected outputs, and troubleshooting.

### Out of Scope
- WorkIQ MCP happy-path JSON ingestion (already delivered in [Sprint 2](./sprint-02-uc1-spec-parser-happy-path.md)).
- Production deployments (still staging only).
- Drift detection (Sprint 5).
- PR Review Agent automation (Sprint 4 — but UC1's ADO PRs will be the first real targets).
- Any `.xlsx` parsing code in this repo (handled by WorkIQ MCP server).

---

## 4. User Stories & Acceptance Criteria

### S3-1 — WorkIQ MCP Excel happy path
**As an** SA
**I want** to author the spec as an Excel file in SharePoint and have the agent ingest it via WorkIQ MCP
**so that** non-developer SAs can use a familiar tool.

**Acceptance**:
- [ ] Golden-task fixture in `agents/spec-parser/golden-tasks.md` covers a SharePoint URL pointing at a `.xlsx`. The WorkIQ MCP response returns a JSON conforming to `schemas/landing-zone-spec.schema.json`.
- [ ] The agent's Output Contract makes no distinction between Excel and JSON sources — it always validates the JSON returned by WorkIQ MCP against the schema.
- [ ] If the WorkIQ MCP server reports an unmappable cell / missing required field, the agent posts a path-pointing error referencing the WorkIQ source location (sheet + cell, as returned by the MCP server).
- [ ] No file content is logged or echoed; only metadata + hash.
- [ ] *Implements*: `FR-UC1-002`, `FR-UC1-011`.

### S3-2 — Azure DevOps MCP write path (branch + commit + ADO PR)
**As an** agent
**I want** to create a branch in the customer's ADO Repo, commit the generated parameter files, and open an ADO PR
**so that** the customer's existing ADO review workflow owns the change.

**Acceptance**:
- [ ] `.github/copilot/mcp.json` `azure-devops-mcp` entry side-effect ceiling promoted from `read` (Sprint 2) to `write` (this sprint). CODEOWNERS-approved.
- [ ] `agents/spec-parser/AGENT.md` declares ADO MCP write tools (`create-branch`, `commit`, `open-pr`) with side-effect ceiling `write`. No `delete` or `force-push` paths.
- [ ] Branch name template: `landingzone/<spec-name>/<short-run-id>`.
- [ ] Single squashed commit signed by the agent's identity, Conventional-Commits formatted.
- [ ] ADO PR title: `feat(landing-zone): provision <name>`; body rendered from `samples/azuredevops/pull_request_template.md` with spec summary + generated files + validation report + agent-run link.
- [ ] Refusal rule: agent never merges, never force-pushes, never deletes branches in ADO.
- [ ] *Implements*: `FR-UC1-006`, `FR-UC1-012`.

### S3-3 — Azure Policy enforcement on staging
**As a** security reviewer
**I want** the staging subscription to enforce baseline policies
**so that** non-compliant specs fail safely before any production change.

**Acceptance**:
- [ ] Policy initiative Bicep module at `infra/landing-zone/policy/baseline.bicep` — UC1 output artefact. Enforces required tags (`env`, `owner`, `costCenter`, `workload`), allowed locations (`westeurope`, `swedencentral`), deny public IPs on storage.
- [ ] Policy module builds clean with `az bicep build`; included in `scripts/preflight.ps1`.
- [ ] Policy violations during the staging deploy step cause the deploy to fail; the agent surfaces a clear error in the validation report and the ADO PR description.
- [ ] Golden-task fixture `uc1-policy-violation` verifies the negative path (deploy fails, PR opened with policy violation report).
- [ ] *Implements*: `FR-UC1-013`, `NFR-SEC-003`.

### S3-4 — OBO authentication at the MCP layer
**As a** security reviewer
**I want** user-triggered runs to act as the SA at the MCP layer
**so that** WorkIQ + ADO + Azure audit trails attribute actions to the SA, not a shared service principal.

**Acceptance**:
- [ ] `agents/spec-parser/AGENT.md` declares that OBO is the default identity mode when the trigger is a human-filed issue. Service-principal fallback is documented and only used for golden-task replays.
- [ ] WorkIQ MCP + Azure DevOps MCP entries in `.github/copilot/mcp.json` document the OBO scopes required (`Code (R/W)`, `PR Threads (R/W)`, `Work Items (R)` for ADO; equivalent SharePoint scopes for WorkIQ).
- [ ] ADO commit author = SA's identity; PR author = SA. Verified by the demo script.
- [ ] [ADR-0007](../docs/adr/0007-obo-vs-service-identity.md) documents OBO-vs-service-identity choice and the fallback rules.
- [ ] *Implements*: `NFR-SEC-002`, `NFR-GOV-005`.

### S3-5 — Full UC1 golden-task suite
**Acceptance**:
- [ ] 6+ golden-task fixtures in `agents/spec-parser/golden-tasks.md`: happy-path JSON (S2), SharePoint URL with Excel source, missing-tag, policy-violation, ADO-unreachable, malformed WorkIQ response.
- [ ] Each fixture has `requirement:` front-matter listing FR/NFR IDs.
- [ ] Replay green via `eval-goldens.yml` (or manual replay) — pass rate 100 % expected (≥ 95 % minimum).
- [ ] *Implements*: `NFR-GOV-006`, `FR-PLT-003`.

### S3-6 — Runbook
**Acceptance**:
- [ ] `docs/runbooks/uc1-build-subscription.md` documents: prerequisites (WorkIQ access, ADO project, staging RG), the issue-template flow, the `approved-to-apply` step, expected outputs (GitHub draft PR + ADO PR), and troubleshooting (WorkIQ 403, ADO permission errors, Azure quota, policy denials).
- [ ] Runbook is reachable from `AGENTS.md` `spec-parser` row.
- [ ] *Implements*: `NFR-OPS-002`.

---

## 5. Deliverables

| Artifact | Path |
|----------|------|
| Expanded golden tasks | `agents/spec-parser/golden-tasks.md` (6+ fixtures) |
| ADO PR template (UC1 output) | `samples/azuredevops/pull_request_template.md` |
| Policy initiative (UC1 output) | `infra/landing-zone/policy/baseline.bicep` |
| MCP allow-list update | `.github/copilot/mcp.json` (`azure-devops-mcp` ceiling `write`; OBO scopes documented for `workiq-mcp` + `azure-devops-mcp`) |
| Runbook | `docs/runbooks/uc1-build-subscription.md` |
| ADR | `docs/adr/0007-obo-vs-service-identity.md` |

---

## 6. Dependencies

- [Sprint 2](./sprint-02-uc1-spec-parser-happy-path.md) complete and stable — WorkIQ MCP read + ADO MCP read + Azure MCP `deploy` (gated) proven.
- WorkIQ MCP server returns Excel sources as JSON conforming to `schemas/landing-zone-spec.schema.json` (verified during golden-task fixture authoring).
- A customer ADO project + repo where the agent can create branches and open PRs under the SA's OBO identity.
- M365 / Entra tenant where OBO can be exercised with the SA's account.

---

## 7. Risks & Mitigations

| Risk | Mitigation |
|------|------------|
| WorkIQ MCP Excel mapping diverges from JSON expectations | Strict schema in `schemas/landing-zone-spec.schema.json`; capture observed Excel-source response shape as a golden-task fixture; refuse runs that don't validate. |
| OBO token scopes mismatch | Validate scopes with a no-op call early in the sprint; document required scopes in [ADR-0007](../docs/adr/0007-obo-vs-service-identity.md). |
| Azure Policy denials block legitimate specs | Document policy exemption procedure (manual, separate PR to `infra/landing-zone/policy/`) in the runbook. |
| ADO MCP write surface is broader than required | Refusal rules in `agents/spec-parser/AGENT.md` enumerate the allowed ADO MCP tools; everything else is refused. |

---

## 8. Exit Criteria

- [ ] All user stories done.
- [ ] M4 demo executed.
- [ ] All golden-task fixtures green (≥ 95 % pass rate).
- [ ] Runbook published; an SA can self-serve a UC1 build end-to-end.
- [ ] **Roadmap Phase 1 exit gate met**: full UC1 end-to-end demo with WorkIQ Excel input, ADO PR output, OBO identity, all human approval gates enforced.

---

## 9. Demo Script (M4)

1. SA files an issue from `.github/ISSUE_TEMPLATE/uc1-build-subscription.yml` pasting a SharePoint URL pointing to an Excel landing-zone spec.
2. Copilot coding agent fetches via WorkIQ MCP under the SA's OBO identity → shows hash + metadata (no file content) in the draft PR.
3. Agent renders `.bicepparam` files; posts `az bicep what-if` summary on the draft PR.
4. SA reviews and posts `approved-to-apply`.
5. Staging deploy runs. One resource intentionally violates the policy initiative → deploy fails → agent surfaces a clear error on the GitHub PR → SA fixes the spec → re-run succeeds.
6. Agent commits to the customer's ADO Repo on a `landingzone/...` branch and opens an ADO PR with the validation report rendered from the PR template.
7. Show ADO audit trail: commit author = SA, PR author = SA (OBO confirmed). Agent identity has no merge / push / delete rights — negative test.

---

## 10. Related Documents

- [sprints/SPRINT_PLAN.md](./SPRINT_PLAN.md)
- [sprints/sprint-02-uc1-spec-parser-happy-path.md](./sprint-02-uc1-spec-parser-happy-path.md)
- [sprints/sprint-04-uc3-pr-review-agent.md](./sprint-04-uc3-pr-review-agent.md)
- [docs/SOLUTION_OVERVIEW.md §5.1](../docs/SOLUTION_OVERVIEW.md#51-use-case-1--initial-azure-subscription-build-landing-zone-provisioning)
- [docs/SECURITY.md](../docs/SECURITY.md)
