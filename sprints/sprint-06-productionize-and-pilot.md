# Sprint 6 — Productionize & Pilot Demo

| Field | Value |
|-------|-------|
| **Version** | 2.1.0 |
| **Date** | 2026-05-25 |
| **Author** | Urs Rüegg |
| **Status** | Draft |
| **Previous Version** | 1.0.0 (pilot BU onboarding); 1.1.0 reframed as PRD-driven pilot demo per SPRINT_PLAN §9 Q4 — Cosmos `agent-registry`, CA on Entra Agent IDs, Agent 365 telemetry, `eval-nightly.yml`, `prod` environment with private endpoints and `deploy-prod.yml`; 2.0.0 reframed the sprint around the **GitHub Copilot coding agent runtime** per [ADR-0002](../docs/adr/0002-runtime-is-github-copilot-coding-agent.md) via a §3.1 amendment overlay; 2.1.0 MINOR — removes the 1.x retained-for-traceability text and the §3.1 amendment overlay, rewriting §§3–5, 9 in final form. **S6-6 (`prod` environment + manual gate) is explicitly out of scope** per ADR-0002 (the platform has no `prod` environment). User-story IDs `S6-1..S6-7` preserved with reinterpreted acceptance criteria. |

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
9. [Demo Script](#9-demo-script-m7)
10. [Related Documents](#10-related-documents)

---

## 1. Goal & Outcomes

All three use cases are functional after Sprint 5, but they need pilot-grade
governance and a **rehearsed pilot demonstration** before real customers
adopt them.

By the end of the sprint:

- The top-level **`AGENTS.md`** registry is the single source of truth for
  every agent (status, owner, MCP servers in use, side-effect ceiling,
  golden-task path, `promptHash` = Git commit SHA of `agents/<name>/AGENT.md`,
  last-reviewed date). Pause / retire is a PR.
- **Conditional Access** is configured on the MCP-side service principals
  (Azure MCP, Azure DevOps MCP) and on GitHub org SSO for human callers.
  There is no platform-side Entra Agent ID to govern (per ADR-0002).
- **GitHub-native telemetry** aggregation runs weekly via a GitHub Actions
  workflow that mines the Copilot run history + audit log + Git history
  and posts a summary issue.
- **Continuous evaluation** (`.github/workflows/eval-nightly.yml`) replays
  every agent's `golden-tasks.md` on a stable LLM deployment; regressions
  open an issue automatically.
- **SLOs + runbooks** published for every agent. Runbooks include the
  "disable agent" PR step (remove MCP servers from `mcp.json` + flip the
  `AGENTS.md` row to `paused`).
- A **PRD-driven pilot demo** exercises the three shared use cases
  ([UC1](../docs/PRD.md#41-uc1--subscription-build-fr-uc1-),
  [UC2](../docs/PRD.md#42-uc2--drift-detection-fr-uc2-),
  [UC3](../docs/PRD.md#43-uc3--pr-review-fr-uc3-)) end-to-end against a
  representative reference workload — not a specific BU's production stack.

---

## 2. Use Cases Addressed

- **All three** (UC1, UC2, UC3) — hardened, not extended.

---

## 3. Scope

### In Scope
- **`AGENTS.md`-driven registry**: every agent row carries `name`, `owner`, `triggers`, `mcp_servers`, `side_effect_ceiling`, `golden_tasks_path`, `status (active | paused | retired)`, `last_reviewed_at`, `promptHash` (Git commit SHA of `agents/<name>/AGENT.md`).
- **Pause / retire as a PR**: `pause` = PR setting `status: paused` in `AGENTS.md` **and** removing the agent's MCP servers from `.github/copilot/mcp.json`. `retire` = `status: retired` + delete `agents/<name>/`. Both flows are CODEOWNERS-gated.
- **Conditional Access on MCP-side identities**: CA policies attached to the Azure MCP and Azure DevOps MCP service principals (location, sign-in risk, WIF-only). CA on GitHub org SSO governs human callers. Both are documented in `docs/SECURITY.md` and a sample policy snapshot lives at `samples/conditional-access/` (JSON, for reference — applied via Microsoft Graph by the customer's identity team).
- **GitHub-native weekly aggregation workflow** at `.github/workflows/agent-telemetry-weekly.yml` — queries the Copilot run history + GitHub audit log + Git history and posts a summary issue (runs per agent, latency proxy, eval pass-rate trend, top failing prompts). No App Insights workbook, no Cosmos.
- **Continuous evaluation** at `.github/workflows/eval-nightly.yml` — replays every `agents/<name>/golden-tasks.md` against a stable LLM deployment; regressions > 5 % from baseline auto-open an issue with the `eval-regression` label. Baselines stored in `evals/baselines/<agent>.json` (Git-tracked).
- **SLOs** at `docs/slo/uc1.md`, `docs/slo/uc2.md`, `docs/slo/uc3.md` — availability + latency targets + error budgets, measured against GitHub-native signals.
- **Runbooks** at `docs/runbooks/incident-*.md` covering the top 5 incident classes: model deprecation, ADO MCP outage, WorkIQ MCP permission failure, GitHub Actions outage, prompt regression. Each runbook includes the "disable agent" PR step.
- **PRD-driven pilot demo** assets: `samples/reference-workload/`, `docs/demo/pilot-demo.md`, `docs/onboarding/adopter-template.md`.
- **ADR-0008** reframed as "Agent Registry via AGENTS.md + MCP allow-list" — documents the registry schema, pause/retire flow, and why no Cosmos.

### Out of Scope (explicit)
- **`prod` environment + `deploy-prod.yml` + private endpoints for KV / Cosmos** — dropped from this sprint. Per [ADR-0002](../docs/adr/0002-runtime-is-github-copilot-coding-agent.md) the platform has no `prod` environment to deploy. Customer landing zones (UC1 outputs) own their own `prod` deployments via their own pipelines.
- Cosmos container `agent-registry` (replaced by `AGENTS.md`).
- Application Insights workbook `infra/monitor/workbook-agent-365.json` (replaced by the weekly aggregation issue). May be reintroduced later as a UC1 *output* artefact for customer landing zones.
- Agent 365 telemetry custom events (`agent.run.start` etc.) — Copilot run history + GitHub audit log are the telemetry.
- Multi-BU scale-out (Phase 4).
- BU-specific onboarding artefacts.
- Self-service agent onboarding (Phase 4).
- Auto-remediation of incidents (kept manual for pilot).

---

## 4. User Stories & Acceptance Criteria

### S6-1 — Agent Registry (`AGENTS.md`)
**As a** security reviewer
**I want** one place that lists every agent, owner, MCP servers in use, side-effect ceiling, prompt SHA, and lifecycle status
**so that** governance reviews are practical.

**Acceptance**:
- [ ] Top-level `AGENTS.md` lists every agent (orchestrator, spec-parser, pr-review, drift-analyzer) with columns: `name`, `owner`, `triggers`, `mcp_servers`, `side_effect_ceiling`, `golden_tasks_path`, `status`, `last_reviewed_at`, `promptHash`.
- [ ] `promptHash` recorded as the Git commit SHA of `agents/<name>/AGENT.md` at last review; automation in `.github/workflows/agent-telemetry-weekly.yml` flags drift between `promptHash` and the current HEAD SHA of `agents/<name>/AGENT.md`.
- [ ] Pause / retire flows are PRs; CODEOWNERS-gated. Pause additionally removes the agent's entries from `.github/copilot/mcp.json` in the same PR.
- [ ] *Implements*: `FR-PLT-006`, `NFR-GOV-003`.

### S6-2 — Conditional Access on MCP-side identities + GitHub org SSO
**As a** security reviewer
**I want** Conditional Access on the service principals used by Azure / ADO MCP and on GitHub org SSO
**so that** anomalous usage is blocked.

**Acceptance**:
- [ ] CA policies attached to the Azure MCP service principal and the Azure DevOps MCP service principal: WIF-only, IP allow-list, deny on `high` sign-in risk.
- [ ] GitHub org SSO governed by CA on the identity provider side (documented in `docs/SECURITY.md`); applies to humans posting `approved-to-apply`.
- [ ] Reference policy JSON in `samples/conditional-access/` for the customer's identity team to apply.
- [ ] Negative test: simulated sign-in from a non-allowlisted IP is blocked and logged.
- [ ] *Implements*: `NFR-SEC-005`, `NFR-SEC-006`.

### S6-3 — GitHub-native telemetry aggregation
**As a** platform owner
**I want** a weekly summary of agent activity without any custom telemetry infrastructure
**so that** I can reason about health without standing up App Insights.

**Acceptance**:
- [ ] `.github/workflows/agent-telemetry-weekly.yml` runs on Mondays UTC; queries GitHub audit log + Copilot run history + recent issues/PRs with `agent:` labels.
- [ ] Workflow posts (or updates) a `agent-telemetry-weekly` issue with: runs per agent, latency proxy (issue-creation → final-comment timestamp), eval pass-rate trend, top failing prompts, `promptHash` drift list.
- [ ] Aggregation is read-only; never edits agent files.
- [ ] *Implements*: `NFR-OPS-004`.

### S6-4 — Continuous evaluation (`eval-nightly.yml`)
**Acceptance**:
- [ ] `.github/workflows/eval-nightly.yml` runs nightly UTC; replays every agent's `golden-tasks.md` on a stable LLM deployment.
- [ ] Results compared to baselines in `evals/baselines/<agent>.json`; regressions > 5 % auto-open an issue with the `eval-regression` label assigned to the agent's owner.
- [ ] Daily summary posted to a Teams channel via the existing webhook secret (same pattern as UC2).
- [ ] *Implements*: `NFR-GOV-006`, `FR-PLT-003`.

### S6-5 — SLOs + runbooks
**Acceptance**:
- [ ] `docs/slo/uc1.md`, `docs/slo/uc2.md`, `docs/slo/uc3.md` define availability + latency SLOs and error budgets measured against GitHub-native signals.
- [ ] Runbooks `docs/runbooks/incident-*.md` for the top 5 incident classes: model deprecation, ADO MCP outage, WorkIQ MCP permission failure, GitHub Actions outage, prompt regression.
- [ ] Every runbook includes the "disable agent" PR step (status → `paused` + remove MCP servers).
- [ ] *Implements*: `NFR-OPS-002`, `NFR-OPS-005`.

### S6-6 — *(out of scope — see §3 Out of Scope)*
The original v1.1.0 story ("`prod` environment + manual gate + private
endpoints") is **explicitly dropped** in v2.x because the platform has no
`prod` environment per [ADR-0002](../docs/adr/0002-runtime-is-github-copilot-coding-agent.md).
The ID is retained as a placeholder so downstream traceability matrices
(FR/NFR references that pointed at S6-6) can be re-routed in their next
update. No acceptance criteria.

### S6-7 — PRD-driven pilot demo
**As a** pilot demo coordinator
**I want** a rehearsed end-to-end demonstration of UC1/UC2/UC3 against a representative reference workload
**so that** prospective adopters can evaluate the platform without committing a production stack first.

**Decision context**: per [SPRINT_PLAN.md §9 Q4](./SPRINT_PLAN.md#9-open-questions--resolutions),
we do not onboard a specific BU in this sprint; we instead build a repeatable
PRD-driven demo.

**Acceptance**:
- [ ] Reference workload defined in `samples/reference-workload/` — a representative landing zone spec + repo layout covering the resource types described in the [PRD](../docs/PRD.md).
- [ ] Demo script `docs/demo/pilot-demo.md` walks UC1 (build), UC2 (drift), UC3 (review) end-to-end against the reference workload, with expected outputs and known checkpoints.
- [ ] Demo runs cleanly twice in a row from a clean staging RG — captured as a recorded dry-run.
- [ ] Metrics captured during the demo: # of UC1 runs, # of UC3 PRs reviewed, # of drift items detected, end-to-end latency per use case.
- [ ] Onboarding guide template `docs/onboarding/adopter-template.md` (placeholder, no BU specifics) ready for future Phase 4 adoption.
- [ ] *Implements*: `FR-UC1-014`, `FR-UC2-010`, `FR-UC3-010`, `NFR-USE-001`, `NFR-USE-002`.

---

## 5. Deliverables

| Artifact | Path |
|----------|------|
| Agent Registry | `AGENTS.md` (top-level) — schema updated to include `status`, `last_reviewed_at`, `promptHash` |
| Conditional Access reference | `samples/conditional-access/*.json` + `docs/SECURITY.md` update |
| Weekly telemetry workflow | `.github/workflows/agent-telemetry-weekly.yml` |
| Nightly eval workflow | `.github/workflows/eval-nightly.yml` |
| Eval baselines | `evals/baselines/<agent>.json` |
| SLOs | `docs/slo/uc1.md`, `docs/slo/uc2.md`, `docs/slo/uc3.md` |
| Runbooks | `docs/runbooks/incident-*.md` |
| Pilot demo | `samples/reference-workload/`, `docs/demo/pilot-demo.md`, `docs/onboarding/adopter-template.md` |
| ADR | `docs/adr/0008-agent-registry-and-lifecycle.md` (reframed: AGENTS.md-driven) |

> **Note**: `prod` environment + `deploy-prod.yml` + private endpoints from
> v1.1.0 are not delivered (see §3 Out of Scope). Customer landing zones own
> their own `prod` deployments as UC1 outputs.

---

## 6. Dependencies

- Sprints 0–5 complete and demonstrated.
- Reference workload sample agreed (no BU sponsor required per [SPRINT_PLAN.md §9 Q4](./SPRINT_PLAN.md#9-open-questions--resolutions)).
- Customer identity team available to apply CA reference policies to their MCP-side service principals.
- Security sign-off scheduled mid-sprint.

---

## 7. Risks & Mitigations

| Risk | Mitigation |
|------|------------|
| Conditional Access misconfig locks out the MCP service principals | Stage policies in report-only mode first; flip to enforce after a 1-week observation window; the reference policy JSON in `samples/conditional-access/` ships in report-only mode by default. |
| Continuous eval cost overruns | Cap nightly run to a fixed token budget; alert on exceedance via the `eval-regression` issue pipeline. |
| Pilot demo treated as a production rollout | Demo script and `docs/onboarding/adopter-template.md` explicitly mark demo scope; written success criteria gate any later real onboarding. |
| `AGENTS.md` drifts from `.github/copilot/mcp.json` | Weekly aggregation workflow asserts the `mcp_servers` column in `AGENTS.md` matches `mcp.json` and opens an issue on mismatch. |
| `promptHash` drift unnoticed | Same weekly workflow lists agents whose `agents/<name>/AGENT.md` HEAD SHA differs from the `promptHash` column. |

---

## 8. Exit Criteria

- [ ] All in-scope user stories done (S6-1..S6-5, S6-7; S6-6 is explicitly out of scope, no work required).
- [ ] M7 demo executed.
- [ ] Security sign-off received.
- [ ] PRD-driven pilot demo runs end-to-end twice without manual intervention.
- [ ] **Roadmap Phase 2 exit gate met**: approved by security, compliance, and platform governance; reusable agent templates published.

---

## 9. Demo Script (M7)

1. Walk through the top-level `AGENTS.md` — show every agent row, owner, MCP servers, side-effect ceiling, `promptHash`, `last_reviewed_at`.
2. Pause one agent via PR: set `status: paused` + remove MCP servers from `.github/copilot/mcp.json` in a single PR → merge → file an issue that would normally invoke that agent → show the agent declines (golden-task style refusal) because its MCP servers are absent.
3. Trigger `.github/workflows/eval-nightly.yml` manually → green → show Teams summary message. Inject a regression in a golden-task fixture → re-run → show the automatically-opened `eval-regression` issue.
4. Show `samples/conditional-access/` reference policies + a denied sign-in from a non-allowlisted IP in the customer's Entra audit log (recorded screencap).
5. Walk through one runbook (e.g., "Prompt regression → rollback") end-to-end including the "disable agent" PR step.
6. Run the PRD-driven pilot demo against `samples/reference-workload/`: UC1 builds the landing zone (WorkIQ spec → ADO PR → `approved-to-apply` → staging deploy → validation), UC3 reviews the PR automatically, UC2 detects an injected drift the next morning. Record metrics in the demo tracker.
7. Note out loud: there is no `prod` environment for the platform itself to demo (per ADR-0002); customer landing zones own their own `prod`. Show one of the UC1-output `prod` deployments in the customer's pipeline as the parallel.

---

## 10. Related Documents

- [sprints/SPRINT_PLAN.md](./SPRINT_PLAN.md)
- [sprints/sprint-05-uc2-drift-analyzer.md](./sprint-05-uc2-drift-analyzer.md)
- [docs/SOLUTION_OVERVIEW.md §6](../docs/SOLUTION_OVERVIEW.md#6-governance--compliance)
- [docs/SOLUTION_OVERVIEW.md §8](../docs/SOLUTION_OVERVIEW.md#8-phased-roadmap)
- [docs/SECURITY.md](../docs/SECURITY.md)
- [docs/AI.md](../docs/AI.md)
- [docs/ALM_PLAN.md](../docs/ALM_PLAN.md)
