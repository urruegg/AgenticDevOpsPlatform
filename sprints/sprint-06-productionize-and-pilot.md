# Sprint 6 — Productionize & Pilot Demo

| Field | Value |
|-------|-------|
| **Version** | 1.1 |
| **Date** | 2026-05-18 |
| **Author** | Urs Rüegg |
| **Status** | Draft |
| **Previous Version** | 1.0 (pilot BU onboarding) |

> **Window**: 2026-08-03 → 2026-08-14 (2 weeks)
> **Theme**: Harden the platform for **pilot demonstration**: centralized
> agent registry, Conditional Access, Agent 365 telemetry, SLOs, continuous
> evaluation, and a **PRD-driven pilot demo** exercising UC1/UC2/UC3 end to
> end. Per [SPRINT_PLAN.md §9 Q4](./SPRINT_PLAN.md#9-open-questions--resolutions),
> pilot work focuses on the **shared use cases in the [PRD](../docs/PRD.md)**,
> not a single business unit. Marks **end of roadmap Phase 2 (Pilot)**.

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
governance, observability, and a **rehearsed pilot demonstration** before
real customers adopt them.

By the end of the sprint:

- Central **Agent Registry** (Cosmos DB + small portal/CLI) lists every agent
  identity, owner, scopes, and lifecycle status.
- **Conditional Access** policies applied to all agent identities.
- **Agent 365** telemetry integration captures every agent run.
- **Continuous evaluation** runs nightly on a curated golden-set and trends in
  Application Insights.
- **SLOs + runbooks** published for every agent.
- A **PRD-driven pilot demo** exercises the three shared use cases
  ([UC1](../docs/PRD.md#41-uc1--initial-azure-subscription-build), [UC2](../docs/PRD.md#42-uc2--ongoing-drift-detection),
  [UC3](../docs/PRD.md#43-uc3--pull-request-reviews)) end-to-end against a
  representative reference workload — not a specific BU's production stack.

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
- **PRD-driven pilot demo**: a curated reference workload + scripted scenarios that exercise UC1, UC2, and UC3 end-to-end. Replaces BU-specific onboarding per [SPRINT_PLAN.md §9 Q4](./SPRINT_PLAN.md#9-open-questions--resolutions).
- `prod` environment: Bicep deployment via `deploy-prod.yml` with manual approval gate.
- Private endpoints for Key Vault and Cosmos in `prod`.

### Out of Scope
- Multi-BU scale-out (Phase 4 — future).
- BU-specific onboarding artefacts (subscription registry seed, ADO project linking, spec library) — generalised into the PRD-driven demo; per-BU instances are a Phase 4 activity.
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

### S6-7 — PRD-driven pilot demo
**As a** pilot demo coordinator
**I want** a rehearsed end-to-end demonstration of UC1/UC2/UC3 against a representative reference workload
**so that** prospective adopters can evaluate the platform without committing a production stack first.

**Decision context**: per [SPRINT_PLAN.md §9 Q4](./SPRINT_PLAN.md#9-open-questions--resolutions),
we do not onboard a specific BU in this sprint; we instead build a repeatable
PRD-driven demo.

**Acceptance**:
- [ ] Reference workload defined in `samples/reference-workload/` (a representative landing zone spec + repo layout covering the resource types described in the [PRD](../docs/PRD.md)).
- [ ] Demo script `docs/demo/pilot-demo.md` walks UC1 (build), UC2 (drift), UC3 (review) end-to-end against the reference workload, with expected outputs and known checkpoints.
- [ ] Demo runs cleanly twice in a row from a clean staging RG — captured as a recorded dry-run.
- [ ] Metrics captured during the demo: # of UC1 runs, # of UC3 PRs reviewed, # of drift items detected, end-to-end latency per use case.
- [ ] Onboarding guide template `docs/onboarding/adopter-template.md` (placeholder, no BU specifics) ready for future Phase 4 adoption.
- [ ] *Implements*: `FR-UC1-014`, `FR-UC2-010`, `FR-UC3-010`, `NFR-USE-001`, `NFR-USE-002`.

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
| Pilot demo | `samples/reference-workload/`, `docs/demo/pilot-demo.md`, `docs/onboarding/adopter-template.md` |
| ADR | `docs/adr/0008-agent-registry-and-lifecycle.md` |

---

## 6. Dependencies

- Sprints 0–5 complete and demonstrated.
- Reference workload sample agreed (no BU sponsor required per [SPRINT_PLAN.md §9 Q4](./SPRINT_PLAN.md#9-open-questions--resolutions)).
- Security sign-off scheduled mid-sprint.
- `prod` subscription provisioned with required quota.

---

## 7. Risks & Mitigations

| Risk | Mitigation |
|------|------------|
| Conditional Access misconfig locks out agents | Stage policies in report-only mode first; flip to enforce only after observation window. |
| Continuous eval cost overruns | Cap nightly run to a fixed token budget; alert on exceedance. |
| Pilot demo treated as a production rollout | Demo script and `docs/onboarding/adopter-template.md` explicitly mark demo scope; written success criteria gate any later real onboarding. |
| `prod` private endpoints break CI deploy | Use deployment scripts with self-hosted runner or grant CI's federated identity scoped network exception. |

---

## 8. Exit Criteria

- [ ] All user stories done.
- [ ] M7 demo executed.
- [ ] Security sign-off received.
- [ ] PRD-driven pilot demo runs end-to-end twice without manual intervention.
- [ ] **Roadmap Phase 2 exit gate met**: approved by security, compliance, and platform governance; reusable agent templates published.

---

## 9. Demo Script (M7)

1. Open the Agent 365 workbook → show runs, latency, eval trends across all agents.
2. Show Agent Registry CLI: list agents, pause one, demonstrate the paused agent rejects invocations.
3. Trigger nightly eval manually → green; show Teams summary message.
4. Show Conditional Access policies + a denied sign-in from a non-allowlisted IP in the audit log.
5. Walk through one of the runbooks (e.g., "Prompt regression → rollback") end-to-end.
6. Run the PRD-driven pilot demo against `samples/reference-workload/`: UC1 builds the landing zone, UC3 reviews the PR, UC2 detects an injected drift the next night. Record metrics in the demo tracker.
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
