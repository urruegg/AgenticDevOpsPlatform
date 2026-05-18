# Sprints — Agentic DevOps Platform

| Field | Value |
|-------|-------|
| **Version** | 1.0 |
| **Date** | 2026-05-18 |
| **Author** | Urs Rüegg |
| **Status** | Draft |
| **Previous Version** | — (initial release) |

> **Purpose**: Plan and track the iterative delivery of the Agentic DevOps Platform.
> Each sprint produces a working, demonstrable increment that proves part of the
> end-to-end solution described in [docs/SOLUTION_OVERVIEW.md](../docs/SOLUTION_OVERVIEW.md).

---

## Table of Contents

1. [Goal](#1-goal)
2. [Sprint Cadence & Conventions](#2-sprint-cadence--conventions)
3. [Sprint Index](#3-sprint-index)
4. [Use-Case Coverage Map](#4-use-case-coverage-map)
5. [Definition of Done (DoD)](#5-definition-of-done-dod)
6. [Sprint Document Template](#6-sprint-document-template)
7. [Related Documents](#7-related-documents)

---

## 1. Goal

Prove the Agentic DevOps Platform end-to-end by implementing the three use cases
defined in the solution overview:

- **UC1** — Initial Azure subscription build (landing-zone provisioning)
- **UC2** — Subscription updates (drift & change management)
- **UC3** — Pull request reviews and compliance

The sprint plan delivers these incrementally with **production-grade governance
from sprint 0** (identity, secrets, observability, OIDC), so each demo is
representative of the final platform — not throw-away code.

---

## 2. Sprint Cadence & Conventions

- **Cadence**: 2-week sprints (Sprint 0 is a 1-week bootstrap).
- **Branching**: single-branch model on `main`; feature branches via Copilot
  coding agent per issue, squash-merged after PR review.
- **Commits**: [Conventional Commits](https://www.conventionalcommits.org/) —
  see [.github/copilot-instructions.md](../.github/copilot-instructions.md) §6.
- **Definition of Done**: every sprint must satisfy the
  [Agent PR Completion Contract](../.github/copilot-instructions.md#agent-pr-completion-contract-hard-gate).
- **Eval gates**: any sprint that touches prompts, tools, or agent control flow
  runs `evals/` and attaches results to the PR.
- **Demo gate**: every sprint ends with a live demo of the increment.

---

## 3. Sprint Index

| # | Sprint | Window (target) | Theme | Use Cases |
|---|--------|-----------------|-------|-----------|
| 0 | [Foundation & Tooling](./sprint-00-foundation.md) | 2026-05-18 → 2026-05-22 *(1 wk)* | Repo, IaC, identity, OIDC, observability skeleton | — |
| 1 | [Orchestrator MVP & Tool Contracts](./sprint-01-orchestrator-mvp.md) | 2026-05-25 → 2026-06-05 | Agent framework, orchestrator shell, tool schema, tracing | UC1 prep |
| 2 | [UC1 Spec Parser & Deployment (Happy Path)](./sprint-02-uc1-spec-parser-happy-path.md) | 2026-06-08 → 2026-06-19 | JSON spec → Bicep params → staging deploy → validation | **UC1** |
| 3 | [UC1 End-to-End + WorkIQ + PR](./sprint-03-uc1-end-to-end.md) | 2026-06-22 → 2026-07-03 | SharePoint spec, ADO PR open, Azure Policy, eval harness | **UC1** ✅ |
| 4 | [UC3 PR Review Agent](./sprint-04-uc3-pr-review-agent.md) | 2026-07-06 → 2026-07-17 | PR diff analysis, work-item scope check, policy compliance | **UC3** ✅ |
| 5 | [UC2 Drift Analyzer Agent](./sprint-05-uc2-drift-analyzer.md) | 2026-07-20 → 2026-07-31 | Read-only Azure scan, gap analysis, scheduler, route to UC1 | **UC2** ✅ |
| 6 | [Productionize & Pilot Onboarding](./sprint-06-productionize-and-pilot.md) | 2026-08-03 → 2026-08-14 | Agent registry, Conditional Access, Agent 365, SLOs, runbooks | All |

> Sprint 0–3 ≈ Roadmap Phase 1 (Prototype). Sprints 4–6 ≈ Roadmap Phase 2 (Pilot).
> See [docs/SOLUTION_OVERVIEW.md §8](../docs/SOLUTION_OVERVIEW.md#8-phased-roadmap).

---

## 4. Use-Case Coverage Map

| Use Case | Introduced In | Hardened In | Owner |
|----------|---------------|-------------|-------|
| **UC1** — Subscription build | Sprint 2 (happy path) | Sprint 3 (E2E + PR + WorkIQ) | Spec Parser & Deployment Agent |
| **UC2** — Drift detection | Sprint 5 | Sprint 6 (scheduler hardening) | Drift Analyzer Agent |
| **UC3** — PR review | Sprint 4 | Sprint 6 (Agent ID prod controls) | PR Review Agent |
| Cross-cutting | Sprint 0–1 (identity, tracing, tool framework) | Sprint 6 (Agent 365, SLOs) | Platform team |

---

## 5. Definition of Done (DoD)

A sprint is **Done** when **all** of the following are true:

- [ ] All sprint user stories meet their acceptance criteria.
- [ ] All CI checks pass on `main` (lint, test, IaC validate, security scan, eval).
- [ ] Coverage ≥ 80% on changed files (see [docs/TEST.md](../docs/TEST.md)).
- [ ] Eval results attached to the PR if prompts/tools/agents changed.
- [ ] Documentation updated where contracts or behavior changed.
- [ ] Live demo executed against `dev` environment with audit trace captured.
- [ ] Retro completed, decisions captured as ADRs where applicable.

---

## 6. Sprint Document Template

Each sprint document follows this skeleton (see any
`sprint-NN-*.md` file for an example):

1. Metadata header + Table of Contents
2. Goal & Outcomes
3. Use Cases Addressed
4. Scope (in / out)
5. User Stories & Acceptance Criteria
6. Deliverables
7. Dependencies
8. Risks & Mitigations
9. Exit Criteria
10. Demo Script
11. Related Documents

---

## 7. Related Documents

- [sprints/SPRINT_PLAN.md](./SPRINT_PLAN.md) — overall sprint plan, sequencing rationale, timeline
- [docs/SOLUTION_OVERVIEW.md](../docs/SOLUTION_OVERVIEW.md) — full solution overview & use cases
- [docs/ARCHITECTURE.md](../docs/ARCHITECTURE.md) — system architecture and contracts
- [docs/AI.md](../docs/AI.md) — agent governance and evaluation harness
- [docs/SECURITY.md](../docs/SECURITY.md) — identity, secrets, RBAC
- [docs/ALM_PLAN.md](../docs/ALM_PLAN.md) — CI/CD plan
- [.github/copilot-instructions.md](../.github/copilot-instructions.md) — repo-wide conventions
