# Sprint 3 — UC1 End-to-End + WorkIQ + PR

| Field | Value |
|-------|-------|
| **Version** | 1.0 |
| **Date** | 2026-05-18 |
| **Author** | Urs Rüegg |
| **Status** | Draft |
| **Previous Version** | — (initial release) |

> **Window**: 2026-06-22 → 2026-07-03 (2 weeks)
> **Theme**: Close out **UC1** — ingest specs from SharePoint via WorkIQ, enforce
> Azure Policy on staging, and open a real PR in ADO with the validation report
> attached. Marks **end of roadmap Phase 1 (Prototype)**.

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

Make UC1 **production-shaped**: the SA invokes the agent with a SharePoint
link, the agent fetches the spec via WorkIQ, runs the full Sprint-2 pipeline,
enforces Azure Policy in staging, and opens a PR in ADO with the validation
report attached as the PR description.

End-of-sprint capability:

```
agentic-devops build-subscription "<sharepoint-url-or-fileId>"
```

→ branch + commits in ADO, PR opened, validation report attached, audit trail
complete, all under the orchestrator's Entra Agent ID (OBO from the SA).

---

## 2. Use Cases Addressed

- **UC1 — Initial Azure Subscription Build** (end-to-end with WorkIQ + PR open)

---

## 3. Scope

### In Scope
- WorkIQ MCP integration: fetch spec from SharePoint / OneDrive given a URL or file ID.
- Spec ingestion supports **JSON, YAML, and Excel (.xlsx)** sources from WorkIQ.
- ADO MCP **write** path: create branch, commit files, open PR.
- PR template auto-populated with validation report + agent trace link.
- Azure Policy attached to `stg` subscription enforcing tagging + allowed locations.
- OBO flow: agent acts as the SA when invoked from CLI with the SA's signed-in identity.
- Eval expansion: 6+ golden tasks (incl. Excel spec, SharePoint URL, policy-failing spec).
- Runbook: how an SA invokes UC1 end-to-end.

### Out of Scope
- Production subscription deployments (still staging only).
- Drift detection (Sprint 5).
- PR Review Agent automation (Sprint 4 — but UC1's PR will be a great test target!).

---

## 4. User Stories & Acceptance Criteria

### S3-1 — WorkIQ spec ingestion
**As an** SA
**I want** to point the agent at a SharePoint URL and have it fetch the spec
**so that** I don't need to download files manually.

**Acceptance**:
- [ ] `tools/workiq_fetch.py` retrieves a file by URL/ID through WorkIQ MCP.
- [ ] Tool respects user's M365 permissions (OBO) — confirmed by a negative test (file user can't read returns 403, not data).
- [ ] Supports `.json`, `.yaml`, `.xlsx`. Excel converted to spec JSON via a deterministic mapper.
- [ ] No file content is logged; only metadata + hash.

### S3-2 — ADO branch / commit / PR (write path)
**As an** agent
**I want** to commit generated files to a feature branch and open a PR
**so that** humans can review and merge.

**Acceptance**:
- [ ] Branch name: `landingzone/<spec-name>/<short-run-id>`.
- [ ] Single squashed commit signed by the agent's identity, Conventional-Commits formatted.
- [ ] PR title: `feat(landing-zone): provision <name>` and template-driven body.
- [ ] PR description includes: spec summary, generated files, validation report, App Insights trace link.
- [ ] Tool side-effect class is `write`; requires `confirm=True`.

### S3-3 — Azure Policy enforcement on staging
**As a** security reviewer
**I want** the staging subscription to enforce baseline policies
**so that** non-compliant specs fail safely before any prod change.

**Acceptance**:
- [ ] Initiative attached to `stg` subscription: require tags (`env`, `owner`, `costCenter`, `workload`), allowed locations (`westeurope`, `swedencentral`), deny public IPs on storage.
- [ ] Policy violations cause pipeline failure with a clear error in the agent's validation report.
- [ ] Eval task `uc1-policy-violation` verifies negative path.

### S3-4 — OBO authentication
**As a** security reviewer
**I want** user-triggered runs to act as the user (not the service identity)
**so that** ADO and Azure audit trails attribute actions correctly.

**Acceptance**:
- [ ] OBO flow exchanges the user's token for ADO + Azure scopes.
- [ ] ADO commit author = SA's account; PR author = SA.
- [ ] Service-identity fallback (`--service`) clearly labels actions as `agentic-devops-bot`.
- [ ] ADR-0006 documents OBO vs service-identity choices.

### S3-5 — Full UC1 evaluation harness
**Acceptance**:
- [ ] 6+ golden tasks: happy path JSON, SharePoint URL, Excel spec, missing tag, policy violation, ADO unreachable.
- [ ] Eval pass rate ≥ 95 %; CI blocks merge on regression.
- [ ] Eval results trended in App Insights dashboard.

### S3-6 — Runbook
**Acceptance**:
- [ ] `docs/runbooks/uc1-build-subscription.md` documents prerequisites, command, expected output, troubleshooting (ADO auth, Azure quota, policy denials).

---

## 5. Deliverables

| Artifact | Path |
|----------|------|
| WorkIQ tool | `tools/workiq_fetch.py`, `tools/excel_to_spec.py` |
| ADO write tools | `tools/ado_branch.py`, `tools/ado_commit.py`, `tools/ado_pr_open.py` |
| PR template | `.azuredevops/pull_request_template.md` |
| Policy initiative | `infra/policy/landing-zone-baseline.bicep` |
| OBO auth | `agents/auth/obo.py` |
| Evals | `evals/tasks/uc1/*.yaml` (expanded) |
| Runbook | `docs/runbooks/uc1-build-subscription.md` |
| ADR | `docs/adr/0006-obo-vs-service-identity.md` |

---

## 6. Dependencies

- WorkIQ MCP endpoint available in the dev tenant with the SA's M365 access.
- ADO project permissions for the orchestrator's service identity (commit, PR create) — escalation from Sprint 2's read-only scopes.
- Sprint 2 complete and stable (this sprint builds directly on it).

---

## 7. Risks & Mitigations

| Risk | Mitigation |
|------|------------|
| WorkIQ permission edge cases | Negative-path test in evals; explicit error surface in CLI. |
| Excel-to-spec mapping ambiguity | Strict mapping rules documented; reject unmappable cells with a clear error. |
| OBO token scopes mismatch | Validate scopes in Sprint 0/1 with a no-op call; document required Graph scopes in ADR-0006. |
| Azure Policy denials block legitimate specs | Provide a documented exemption path (manual subscription-level exception) for policy edge cases. |

---

## 8. Exit Criteria

- [ ] All user stories done.
- [ ] M4 demo executed.
- [ ] Eval pass rate ≥ 95 %; coverage ≥ 80 % on changed files.
- [ ] Runbook published; SA can self-serve a build.
- [ ] **Roadmap Phase 1 exit gate met**: end-to-end UC1 demo with full human approval gates.

---

## 9. Demo Script (M4)

1. SA pastes a SharePoint URL pointing to an Excel landing-zone spec.
2. Run `agentic-devops build-subscription <url>`.
3. Agent fetches via WorkIQ → shows hash + metadata (no file content).
4. Generated Bicep params shown locally for SA approval.
5. Staging deploy runs; one resource intentionally violates policy → policy denies → agent surfaces clear error → SA fixes → re-run succeeds.
6. PR opened in ADO with full validation report and trace link.
7. App Insights trace shows OBO identity on every action (SA's account, not service identity).

---

## 10. Related Documents

- [sprints/SPRINT_PLAN.md](./SPRINT_PLAN.md)
- [sprints/sprint-02-uc1-spec-parser-happy-path.md](./sprint-02-uc1-spec-parser-happy-path.md)
- [sprints/sprint-04-uc3-pr-review-agent.md](./sprint-04-uc3-pr-review-agent.md)
- [docs/SOLUTION_OVERVIEW.md §5.1](../docs/SOLUTION_OVERVIEW.md#51-use-case-1--initial-azure-subscription-build-landing-zone-provisioning)
- [docs/SECURITY.md](../docs/SECURITY.md)
