# Sprint 3 — UC1 End-to-End + Excel + Policy + PR

| Field | Value |
|-------|-------|
| **Version** | 1.1 |
| **Date** | 2026-05-18 |
| **Author** | Urs Rüegg |
| **Status** | Draft |
| **Previous Version** | 1.0 (introduced WorkIQ in S3) |

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
9. [Demo Script](#9-demo-script)
10. [Related Documents](#10-related-documents)

---

## 1. Goal & Outcomes

Make UC1 **production-shaped**: building on the WorkIQ MCP integration from
Sprint 2, the SA can now point at a spec stored as **Excel** (in addition to
the JSON shape already supported), the agent runs the full pipeline,
Azure Policy is enforced in staging, and a real PR is opened in ADO with the
validation report attached. Identity moves from service-only to **OBO**.

End-of-sprint capability:

```
agentic-devops build-subscription "<workiq-url-or-id>"
```

→ spec fetched via WorkIQ MCP (JSON **or** Excel), branch + commits in ADO, PR
opened, validation report attached, audit trail complete, all under the
agent's Entra Agent ID **acting on behalf of the SA** (OBO).

---

## 2. Use Cases Addressed

- **UC1 — Initial Azure Subscription Build** (end-to-end with WorkIQ + PR open)

---

## 3. Scope

### In Scope
- WorkIQ MCP **Excel** ingestion: deterministic `.xlsx` → spec JSON mapper.
- ADO MCP **write** path: create branch, commit files, open PR.
- PR template auto-populated with validation report + agent trace link.
- Azure Policy attached to `stg` subscription enforcing tagging + allowed locations.
- **OBO flow**: agent acts as the SA when invoked from CLI with the SA's signed-in identity (replaces the service-only identity from Sprint 2).
- Eval expansion: 6+ golden tasks (incl. Excel spec, SharePoint URL, policy-failing spec).
- Runbook: how an SA invokes UC1 end-to-end.

### Out of Scope
- WorkIQ MCP happy-path JSON ingestion (already delivered in [Sprint 2](./sprint-02-uc1-spec-parser-happy-path.md)).
- Production subscription deployments (still staging only).
- Drift detection (Sprint 5).
- PR Review Agent automation (Sprint 4 — but UC1's PR will be a great test target!).

---

## 4. User Stories & Acceptance Criteria

### S3-1 — WorkIQ MCP: Excel ingestion
**As an** SA
**I want** to author the spec as an Excel file in SharePoint and have the agent ingest it
**so that** non-developer SAs can use a familiar tool.

**Acceptance**:
- [ ] `tools/excel_to_spec.py` deterministically maps `.xlsx` cells to the spec JSON schema from Sprint 2 (`schemas/landing-zone-spec.schema.json`).
- [ ] Unmappable cells / missing required cells produce a path-pointing error referencing the sheet + cell.
- [ ] Tool respects the same `read` side-effect class as the JSON happy path.
- [ ] No file content is logged; only metadata + hash.
- [ ] *Implements*: `FR-UC1-002`, `FR-UC1-011`.

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
| Excel mapper | `tools/excel_to_spec.py` |
| ADO write tools | `tools/ado_branch.py`, `tools/ado_commit.py`, `tools/ado_pr_open.py` |
| PR template | `.azuredevops/pull_request_template.md` |
| Policy initiative | `infra/policy/landing-zone-baseline.bicep` |
| OBO auth | `agents/auth/obo.py` |
| Evals | `evals/tasks/uc1/*.yaml` (expanded) |
| Runbook | `docs/runbooks/uc1-build-subscription.md` |
| ADR | `docs/adr/0007-obo-vs-service-identity.md` |

---

## 6. Dependencies

- [Sprint 2](./sprint-02-uc1-spec-parser-happy-path.md) complete and stable — WorkIQ MCP happy path proven; this sprint builds directly on it.
- ADO project permissions for the orchestrator's service identity (commit, PR create) — escalation from Sprint 2's read-only scopes.
- M365 / Entra tenant where OBO can be exercised with the SA's account.

---

## 7. Risks & Mitigations

| Risk | Mitigation |
|------|------------|
| Excel-to-spec mapping ambiguity | Strict mapping rules documented; reject unmappable cells with a clear error. |
| OBO token scopes mismatch | Validate scopes with a no-op call early in the sprint; document required Graph scopes in ADR-0007. |
| Azure Policy denials block legitimate specs | Provide a documented exemption path (manual subscription-level exception) for policy edge cases. |
| WorkIQ permission edge cases (newly exposed through OBO) | Negative-path test in evals; explicit error surface in CLI. |

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
