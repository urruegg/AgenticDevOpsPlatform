# Sprint 6 — Productionize & Pilot Onboarding

| Field | Value |
|-------|-------|
| **Version** | 1.0 |
| **Date** | 2026-05-18 |
| **Author** | Urs Rüegg |
| **Status** | Draft |
| **Previous Version** | — (initial release) |

> **Window**: 2026-08-03 → 2026-08-14 (2 weeks)
> **Theme**: Harden the platform for **pilot** use: centralized agent registry,
> Conditional Access, Agent 365 telemetry, SLOs, continuous evaluation, and
> first business-unit onboarding. Marks **end of roadmap Phase 2 (Pilot)**.

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

All three use cases are functional after Sprint 5, but they need production-grade
governance, observability, and a documented onboarding path before a real
business unit can adopt them.

By the end of the sprint:

- Central **Agent Registry** (Cosmos DB + small portal/CLI) lists every agent
  identity, owner, scopes, and lifecycle status.
- **Conditional Access** policies applied to all agent identities.
- **Agent 365** telemetry integration captures every agent run.
- **Continuous evaluation** runs nightly on a curated golden-set and trends in
  Application Insights.
- **SLOs + runbooks** published for every agent.
- **One pilot BU** is onboarded with their own subscription registry entries,
  spec library, and ADO project access.

---

## 2. Use Cases Addressed

- **All three** (UC1, UC2, UC3) — hardened, not extended.

---

## 3. Scope

### In Scope
- Agent Registry (Cosmos `agent-registry`): per-agent record with owner, scopes, model, prompt hash, eval baseline, lifecycle status.
- Conditional Access: per-agent-identity policies (location, device, sign-in risk).
- Agent 365 telemetry shipping: `agent.run.start`, `agent.run.end`, `agent.tool.call` custom events; central dashboard.
- Continuous evaluation job: nightly run of full golden-set across all three agents; trending metric `agent.eval.passRate`.
- SLOs: per-agent availability + latency targets documented in `docs/slo/`.
- Runbooks: incident response, model rollback, prompt rollback, agent disablement.
- Pilot BU onboarding: pilot tenant spec, ADO project link, subscription registry seed entries.
- `prod` environment: Bicep deployment via `deploy-prod.yml` with manual approval gate.
- Private endpoints for Key Vault and Cosmos in `prod`.

### Out of Scope
- Multi-BU scale-out (Phase 4 — future).
- Self-service agent onboarding (Phase 4).
- Auto-remediation of incidents (kept manual for pilot).

---

## 4. User Stories & Acceptance Criteria

### S6-1 — Central Agent Registry
**As a** security reviewer
**I want** one place that lists every agent identity, owner, scopes, prompt version, and lifecycle status
**so that** governance reviews are practical.

**Acceptance**:
- [ ] Cosmos container `agent-registry` partitioned by `/tenantId`.
- [ ] Schema: `{agentId, name, owner, entraObjectId, scopes[], modelDeployment, promptHash, evalBaseline, status (active|paused|retired), createdAt, lastReviewedAt}`.
- [ ] CLI `agentic-devops registry list|get|pause|retire <agentId>`.
- [ ] All four agent identities (orchestrator, spec parser, pr reviewer, drift analyzer) registered.

### S6-2 — Conditional Access for agents
**As a** security reviewer
**I want** Conditional Access policies on agent identities
**so that** anomalous usage is blocked.

**Acceptance**:
- [ ] Policies: deny sign-in from outside expected IP ranges; deny on `high` sign-in risk; require workload-identity federation only.
- [ ] Policies attached to each agent's Entra Agent ID.
- [ ] Negative test: simulated sign-in from a non-allowlisted IP is blocked and logged.

### S6-3 — Agent 365 telemetry
**Acceptance**:
- [ ] Every run emits `agent.run.start`, `agent.run.end` with `agentId`, `actorIdentity`, `tenantId`, `latencyMs`, `tokenUsage`, `cost`.
- [ ] Workbook in Application Insights shows: runs per agent per day, p95 latency, eval pass-rate trend, top failing prompts.
- [ ] Data retention 90 days `dev`, 365 days `prod`.

### S6-4 — Continuous evaluation
**Acceptance**:
- [ ] Nightly GitHub Actions job `eval-nightly.yml` runs full golden-set against all agents on a stable LLM deployment.
- [ ] Results posted to App Insights + summarized in a daily Teams message.
- [ ] Any regression > 5 % from baseline auto-creates an ADO Boards bug.

### S6-5 — SLOs and runbooks
**Acceptance**:
- [ ] `docs/slo/uc1.md`, `docs/slo/uc2.md`, `docs/slo/uc3.md` define availability + latency SLOs and error budgets.
- [ ] Runbooks for the top 5 incident classes: model deprecation, ADO outage, WorkIQ permission failure, Cosmos 429, prompt regression.
- [ ] Each runbook includes a "disable agent" step using the registry.

### S6-6 — `prod` environment + manual gate
**Acceptance**:
- [ ] `deploy-prod.yml` workflow with environment approval (`prod`) requiring named approvers.
- [ ] Private endpoints for Key Vault + Cosmos in `prod`.
- [ ] Diagnostic settings → Log Analytics enabled on every prod resource.

### S6-7 — Pilot BU onboarding
**Acceptance**:
- [ ] Onboarding guide `docs/onboarding/pilot-bu.md` documents prerequisites, registry seed, ADO project linking, expected first-week activities.
- [ ] One BU's subscription(s) added to tracked-subscriptions registry; UC1 spec library curated; UC3 webhook bound to BU's ADO project.
- [ ] First-week metrics captured: # of UC1 runs, # of UC3 PRs reviewed, # of drift items detected, time saved estimate.

---

## 5. Deliverables

| Artifact | Path |
|----------|------|
| Agent Registry | `tools/agent_registry.py`, Cosmos container `agent-registry` |
| Conditional Access policies | `infra/policy/conditional-access/*.json` (documented; created via Graph PowerShell) |
| Workbook | `infra/monitor/workbook-agent-365.json` |
| Nightly eval | `.github/workflows/eval-nightly.yml` |
| SLOs | `docs/slo/uc1.md`, `docs/slo/uc2.md`, `docs/slo/uc3.md` |
| Runbooks | `docs/runbooks/incident-*.md` |
| Prod deploy | `.github/workflows/deploy-prod.yml`, `infra/main.bicep` (prod params) |
| Onboarding guide | `docs/onboarding/pilot-bu.md` |
| ADR | `docs/adr/0007-agent-registry-and-lifecycle.md` |

---

## 6. Dependencies

- Sprints 0–5 complete and demonstrated.
- Pilot BU sponsor identified by Sprint 4 (per [SPRINT_PLAN.md §9](./SPRINT_PLAN.md#9-open-questions)).
- Security sign-off scheduled mid-sprint.
- `prod` subscription provisioned with required quota.

---

## 7. Risks & Mitigations

| Risk | Mitigation |
|------|------------|
| Conditional Access misconfig locks out agents | Stage policies in report-only mode first; flip to enforce only after observation window. |
| Continuous eval cost overruns | Cap nightly run to a fixed token budget; alert on exceedance. |
| Pilot BU expectations exceed pilot scope | Written success criteria signed off before onboarding; explicit out-of-scope list. |
| `prod` private endpoints break CI deploy | Use deployment scripts with self-hosted runner or grant CI's federated identity scoped network exception. |

---

## 8. Exit Criteria

- [ ] All user stories done.
- [ ] M7 demo executed.
- [ ] Security sign-off received.
- [ ] One pilot BU active with measurable first-week usage.
- [ ] **Roadmap Phase 2 exit gate met**: approved by security, compliance, and platform governance; reusable agent templates published.

---

## 9. Demo Script (M7)

1. Open the Agent 365 workbook → show runs, latency, eval trends across all agents.
2. Show Agent Registry CLI: list agents, pause one, demonstrate the paused agent rejects invocations.
3. Trigger nightly eval manually → green; show Teams summary message.
4. Show Conditional Access policies + a denied sign-in from a non-allowlisted IP in the audit log.
5. Walk through one of the runbooks (e.g., "Prompt regression → rollback") end-to-end.
6. Run a pilot-BU UC1 build using the BU's own subscription; UC3 reviews the PR; record metrics in the onboarding tracker.
7. Show `deploy-prod.yml` with the manual approval gate and prod resource health.

---

## 10. Related Documents

- [sprints/SPRINT_PLAN.md](./SPRINT_PLAN.md)
- [sprints/sprint-05-uc2-drift-analyzer.md](./sprint-05-uc2-drift-analyzer.md)
- [docs/SOLUTION_OVERVIEW.md §6](../docs/SOLUTION_OVERVIEW.md#6-governance--compliance)
- [docs/SOLUTION_OVERVIEW.md §8](../docs/SOLUTION_OVERVIEW.md#8-phased-roadmap)
- [docs/SECURITY.md](../docs/SECURITY.md)
- [docs/AI.md](../docs/AI.md)
- [docs/ALM_PLAN.md](../docs/ALM_PLAN.md)
