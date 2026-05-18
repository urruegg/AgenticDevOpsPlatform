# Sprint 1 — Orchestrator MVP & Tool Contracts

| Field | Value |
|-------|-------|
| **Version** | 2.1.0 |
| **Date** | 2026-05-25 |
| **Author** | Urs Rüegg |
| **Status** | Draft |
| **Previous Version** | 1.0.0 (Microsoft Agent Framework / Semantic Kernel runtime, Python `agents/orchestrator/`, `tools/base.py`, OpenTelemetry traces to App Insights, Cosmos `agent-runs` container, `agentic-devops` CLI, `pytest` eval harness); 2.0.0 reframed the sprint around the **GitHub Copilot coding agent runtime** per [ADR-0002](../docs/adr/0002-runtime-is-github-copilot-coding-agent.md) via a §3.1 amendment overlay; 2.1.0 MINOR — removes the 1.x retained-for-traceability text and the §3.1 amendment overlay, rewriting §§1, 3–5, 9 in final form. User-story IDs `S1-1..S1-5` preserved with reinterpreted acceptance criteria. |

> **Window**: 2026-05-25 → 2026-06-05 (2 weeks)
> **Theme**: Stand up the agent runtime, tool-contract framework, tracing, and
> first eval harness. Everything specialized agents (UC1–UC3) will reuse.

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
9. [Demo Script](#9-demo-script-m2)
10. [Related Documents](#10-related-documents)

---

## 1. Goal & Outcomes

Deliver a working **Orchestrator Agent** as the first GitHub Copilot
coding-agent prompt file. When an issue is filed from the smoke-echo
template (or `@copilot` is mentioned on any issue), the Copilot coding agent
picks it up, posts a plan, calls the GitHub MCP `add-comment` reference tool,
and produces a draft PR with a structured output. Defines the **MCP tool
contract** that every UC1–UC3 agent will reuse.

By the end of the sprint:

- `agents/orchestrator/AGENT.md` declares Identity, Scope, Tools,
  Refusal Rules, Output Contract, and Confirmation Rules.
- `AGENTS.md` documents the orchestrator's allowed MCP tools and side-effect
  ceiling (`write`). `.github/copilot/mcp.json` enumerates `github-mcp`.
- The agent's smoke-echo flow exercises one MCP tool call (`github-mcp`
  `add-comment`) and posts a plan-then-apply pattern.
- `agents/orchestrator/golden-tasks.md` holds the first happy-path fixture
  plus one failure-mode fixture. Optional `eval-goldens.yml` workflow can
  replay them.
- Run history is captured by the GitHub Copilot coding agent (no Cosmos, no
  App Insights at the platform layer — see [AI.md §5](../docs/AI.md#5-agent-memory--traces)).

---

## 2. Use Cases Addressed

- **None directly** — foundational for UC1 (Sprint 2+), UC2 (Sprint 5), and UC3 (Sprint 4).

---

## 3. Scope

### In Scope
- `agents/orchestrator/AGENT.md` — the orchestrator's system prompt (Identity, Scope, Tools, Refusal Rules, Output Contract, Confirmation Rules for write tools).
- MCP tool contract format documented in `AGENTS.md` (allow-list row per agent: trigger, MCP servers, side-effect ceiling, required permissions, golden-task path).
- `.github/copilot/mcp.json` enumerates `github-mcp` (only MCP server activated in Sprint 1).
- One reference tool exercised end-to-end: GitHub MCP `add-comment` (side-effect `write`).
- `.github/ISSUE_TEMPLATE/smoke-echo.yml` (introduced in Sprint 0) is the trigger; `@copilot` mention on any issue is the alternate trigger.
- `agents/orchestrator/golden-tasks.md` with ≥ 1 happy-path and ≥ 1 failure-mode fixture; each fixture has `requirement:` front-matter listing FR/NFR IDs verified.
- Optional `.github/workflows/eval-goldens.yml` that replays a selected fixture on demand (manual replay acceptable in S1).
- Plan-then-apply pattern: for any tool with side-effect ceiling `write` or higher, the agent posts a plan comment and waits for `approved-to-apply` before firing the tool (per [SECURITY.md §7](../docs/SECURITY.md#7-destructive-actions-policy)).

### Out of Scope
- ADO MCP / WorkIQ MCP / Azure MCP integration (added per use-case sprint: Sprint 2 introduces WorkIQ + ADO + Azure MCP).
- Multiple specialized agents (S2 introduces `spec-parser`).
- Model selection or deployment (the runtime is the GitHub Copilot coding agent; no Azure OpenAI dependency).
- Streaming output, web UI, custom CLI — issues + PRs + comments are the entire UX surface.
- OBO authentication (Sprint 3).

---

## 4. User Stories & Acceptance Criteria

### S1-1 — Orchestrator agent prompt file
**As a** developer
**I want** an `agents/orchestrator/AGENT.md` prompt file with Identity, Scope,
Tools, Refusal Rules, Output Contract, and Confirmation Rules
**so that** the GitHub Copilot coding agent has a stable, version-controlled
specification of how the orchestrator behaves.

**Acceptance**:
- [ ] `agents/orchestrator/AGENT.md` exists with all six required sections (Identity / Scope / Tools / Refusal Rules / Output Contract / Confirmation Rules) per the structure mandated in `.github/copilot-instructions.md` §3.
- [ ] The prompt is picked up by the Copilot coding agent when an issue is filed from `.github/ISSUE_TEMPLATE/smoke-echo.yml`.
- [ ] The agent's draft PR follows the PR Output Contract (lists FR/NFR IDs, requirements-implemented section, test evidence).
- [ ] Errors fail fast with actionable refusal messages — no silent swallows.
- [ ] *Implements*: `FR-PLT-001`, `NFR-GOV-006`.

### S1-2 — MCP tool contract framework
**As an** agent engineer
**I want** every MCP tool the orchestrator may call to be declared in
`AGENTS.md` and `.github/copilot/mcp.json` with its side-effect class and
required permissions
**so that** prompt-injection and untrusted-LLM-output risks are minimized.

**Acceptance**:
- [ ] `AGENTS.md` row for `orchestrator` lists its allowed MCP servers, side-effect ceiling (`write`), required GitHub permissions, and golden-task path.
- [ ] `.github/copilot/mcp.json` enumerates `github-mcp` (only).
- [ ] Side-effect taxonomy documented in `AGENTS.md` (`read | write | deploy | delete`).
- [ ] Additions / changes to `.github/copilot/mcp.json` require CODEOWNERS approval (verified by `.github/CODEOWNERS` rule on the file).
- [ ] *Implements*: `FR-PLT-002`, `NFR-SEC-002`.

### S1-3 — GitHub-native run history & traceability
**As an** operator
**I want** every agent run to be auditable through GitHub-native artefacts
**so that** I can replay any run for debugging or audit without depending on
external infrastructure.

**Acceptance**:
- [ ] Every Copilot coding-agent run leaves: an issue thread, a branch, a draft PR with structured description, and entries in the GitHub audit log.
- [ ] The PR description includes the FR/NFR IDs the run implements (per the PR template).
- [ ] No Cosmos DB / App Insights / OpenTelemetry wiring exists at the platform layer (per [ADR-0002](../docs/adr/0002-runtime-is-github-copilot-coding-agent.md)).
- [ ] *Implements*: `NFR-OPS-001`, `NFR-GOV-006`.

### S1-4 — Golden-task smoke fixture
**As an** agent engineer
**I want** at least one golden-task fixture for the orchestrator replayable on demand
**so that** prompt regressions are caught before merge.

**Acceptance**:
- [ ] `agents/orchestrator/golden-tasks.md` documents ≥ 1 happy-path and ≥ 1 failure-mode fixture.
- [ ] Each fixture defines: input issue body, expected MCP tool calls (ordered or set), expected PR/comment shape, forbidden behaviors.
- [ ] Each fixture has `requirement:` front-matter (`FR-*` / `NFR-*` IDs).
- [ ] Optional `.github/workflows/eval-goldens.yml` can be triggered manually and asserts the PR/comment shape.
- [ ] *Implements*: `FR-PLT-003`, `NFR-GOV-006`.

### S1-5 — Plan-then-apply confirmation rule
**As a** safety reviewer
**I want** the orchestrator to post a plan for any `write`-or-higher tool call
and wait for explicit human approval before firing
**so that** humans can approve before any state mutation.

**Acceptance**:
- [ ] `agents/orchestrator/AGENT.md` declares the plan-then-apply pattern in its Confirmation Rules.
- [ ] For any tool with side-effect ceiling `write` or higher, the agent posts a plan comment and waits for the magic phrase `approved-to-apply` on the same thread before executing.
- [ ] The agent refuses to apply if the approver is the agent itself, a bot, or lacks repo write access (verified via `github-mcp`).
- [ ] Golden-task fixture covers a `write`-tool path with a missing approval (agent should refuse).
- [ ] *Implements*: `NFR-SEC-001`, `NFR-GOV-002`.

---

## 5. Deliverables

| Artifact | Path |
|----------|------|
| Orchestrator prompt | `agents/orchestrator/AGENT.md` |
| Golden tasks | `agents/orchestrator/golden-tasks.md` |
| MCP allow-list | `.github/copilot/mcp.json` (adds `github-mcp` entry) |
| Agent registry update | `AGENTS.md` (orchestrator row) |
| Optional eval workflow | `.github/workflows/eval-goldens.yml` |

---

## 6. Dependencies

- Sprint 0 complete (repo scaffold, Copilot agent config, CI green).
- GitHub MCP server reachable from the Copilot coding-agent runtime.
- **No Azure subscription required** (per [ADR-0002](../docs/adr/0002-runtime-is-github-copilot-coding-agent.md)).

---

## 7. Risks & Mitigations

| Risk | Mitigation |
|------|------------|
| Prompt drift breaks downstream agents | Lock the orchestrator's Output Contract in `AGENT.md`; golden-task fixtures assert the shape. |
| GitHub Copilot coding-agent behaviour changes mid-sprint | Pin the conventions in `.github/copilot-instructions.md`; rely on refusal rules + golden tasks rather than implicit behaviour. |
| Approval phrase (`approved-to-apply`) is forgotten | Document the phrase in `AGENTS.md` §4 + `agents/orchestrator/AGENT.md` Confirmation Rules + PR template. |

---

## 8. Exit Criteria

- [ ] All user stories done.
- [ ] M2 demo executed (see below).
- [ ] At least one golden-task fixture replays cleanly.
- [ ] `AGENTS.md` orchestrator row + `.github/copilot/mcp.json` `github-mcp` entry committed.

---

## 9. Demo Script (M2)

1. Open a new issue from `.github/ISSUE_TEMPLATE/smoke-echo.yml` ("Say hello, then post a comment on this issue.").
2. The Copilot coding agent reads `agents/orchestrator/AGENT.md`, opens a feature branch, and posts a **plan** comment listing the MCP tool calls it intends to make.
3. A reviewer posts `approved-to-apply` on the same issue thread.
4. The agent fires the `github-mcp` `add-comment` tool, then opens a draft PR. PR description includes the FR/NFR IDs and the expected output shape.
5. Show `AGENTS.md` orchestrator row and `.github/copilot/mcp.json` — explain how UC1 will plug in additional MCP servers in Sprint 2.
6. Manually trigger `eval-goldens.yml` (if implemented) and show the green check on the golden-task fixture.

---

## 10. Related Documents

- [sprints/SPRINT_PLAN.md](./SPRINT_PLAN.md)
- [docs/AI.md](../docs/AI.md)
- [docs/DATA.md](../docs/DATA.md)
- [docs/ARCHITECTURE.md](../docs/ARCHITECTURE.md)
