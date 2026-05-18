# Sprint 1 — Orchestrator MVP & Tool Contracts

| Field | Value |
|-------|-------|
| **Version** | 1.0.0 |
| **Date** | 2026-05-18 |
| **Author** | Urs Rüegg |
| **Status** | Draft |
| **Previous Version** | — (initial release) |

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
9. [Demo Script](#9-demo-script)
10. [Related Documents](#10-related-documents)

---

## 1. Goal & Outcomes

Deliver a working **Orchestrator Agent** that can receive a natural-language
prompt, plan a multi-step task, call a stubbed tool, and persist a full trace
to Cosmos DB + Application Insights. Define the **Tool Contract** that all
specialized agents will implement.

By the end of the sprint:

- Microsoft Agent Framework (or Semantic Kernel) runtime selected and wired up.
- Orchestrator agent receives prompts via a thin CLI (`agentic-devops`).
- Tool registration framework with declared schema, side effects, required
  permissions, and a dry-run mode.
- OpenTelemetry tracing → App Insights; structured run document → Cosmos DB.
- Initial eval harness in `evals/` with one smoke golden task.

---

## 2. Use Cases Addressed

- **None directly** — foundational for UC1 (Sprint 2+), UC2 (Sprint 5), and UC3 (Sprint 4).

---

## 3. Scope

### In Scope
- `agents/orchestrator/` — agent shell, prompt template, planner loop.
- `tools/base.py` — `Tool` base class with `name`, `description`, `input_schema`,
  `output_schema`, `side_effects`, `required_permissions`, `dry_run()`, `execute()`.
- Two reference tools:
  - `echo_tool` — pure, no side effects (testing harness).
  - `cosmos_write_trace` — persists run trace.
- Tracing: OpenTelemetry SDK with Azure Monitor exporter; correlated `agentRunId`.
- Cosmos DB: `agent-runs` container partitioned by `/agentRunId`, schema per [docs/DATA.md](../docs/DATA.md).
- CLI: `python -m agentic_devops "<prompt>"`.
- Authentication: `DefaultAzureCredential` → Managed Identity in CI; Azure CLI locally.
- `evals/` harness: pytest-based runner, one smoke task, scores written to App Insights custom event.
- ADR: `0005-agent-framework-choice.md`.

### Out of Scope
- ADO MCP / WorkIQ MCP integration (Sprint 2+).
- Multiple specialized agents.
- Production model deployment (use Azure OpenAI dev instance).
- Streaming output, web UI.

---

## 4. User Stories & Acceptance Criteria

### S1-1 — Orchestrator agent shell
**As a** developer
**I want** to run `agentic-devops "say hello"` and see a planned response
**so that** the agent framework is proven end-to-end.

**Acceptance**:
- [ ] CLI accepts a prompt and prints the agent's final response.
- [ ] Internal plan + tool calls visible in verbose mode.
- [ ] Agent authenticates via `DefaultAzureCredential`.
- [ ] Errors fail fast with actionable messages — no silent swallows.

### S1-2 — Tool contract framework
**As an** agent engineer
**I want** every tool to declare a strict schema and side-effect class
**so that** prompt-injection and untrusted-LLM-output risks are minimized.

**Acceptance**:
- [ ] `Tool` base class with `pydantic` input/output validation.
- [ ] Side-effect taxonomy: `read | write | deploy | delete`.
- [ ] `delete` and `deploy` tools require an explicit `confirm=True` argument.
- [ ] `echo_tool` (read) and `cosmos_write_trace` (write) implemented as references.
- [ ] Tool registration in orchestrator is type-checked.

### S1-3 — Tracing & persistence
**As an** operator
**I want** every agent run to emit an OpenTelemetry trace and a Cosmos DB run document
**so that** I can replay any run for debugging or audit.

**Acceptance**:
- [ ] App Insights shows one span per tool call with name, latency, status.
- [ ] Cosmos DB `agent-runs` container has a document per run with: `agentRunId`, `prompt`, `plan`, `toolCalls[]`, `output`, `latencyMs`, `tokenUsage`, `actorIdentity`, `timestamp`.
- [ ] Partition key `/agentRunId` confirmed; singleton `CosmosClient` reused.
- [ ] 429 retries handled via SDK defaults.

### S1-4 — Eval harness smoke test
**As an** agent engineer
**I want** an evaluation harness running in CI
**so that** prompt regressions are caught before merge.

**Acceptance**:
- [ ] `evals/tasks/smoke_echo.yaml` defines input + expected substring.
- [ ] `pytest evals/ -q` runs the orchestrator against the task and asserts pass.
- [ ] Eval results emitted as App Insights custom event `agent.eval`.
- [ ] CI workflow `eval.yml` runs on PRs touching `agents/**`, `tools/**`, or `evals/**`.

### S1-5 — Tool dry-run / plan mode
**As a** safety reviewer
**I want** every mutating tool to support a dry-run that prints the intended action
**so that** humans can approve before execution.

**Acceptance**:
- [ ] `--dry-run` CLI flag short-circuits all `write|deploy|delete` tools to print the planned action.
- [ ] Confirmed by `cosmos_write_trace` dry-run printing the document it *would* write.

---

## 5. Deliverables

| Artifact | Path |
|----------|------|
| Orchestrator | `agents/orchestrator/` |
| Tool framework | `tools/base.py`, `tools/echo.py`, `tools/cosmos_trace.py` |
| CLI | `agents/cli.py`, console-script `agentic-devops` |
| Tracing | `agents/observability/otel.py` |
| Eval harness | `evals/runner.py`, `evals/tasks/smoke_echo.yaml`, `evals/conftest.py` |
| Workflow | `.github/workflows/eval.yml` |
| ADR | `docs/adr/0005-agent-framework-choice.md` |

---

## 6. Dependencies

- Sprint 0 complete (infra, OIDC, Entra identity).
- Decision: **Microsoft Agent Framework** vs **Semantic Kernel** vs minimal custom — capture in ADR-0005.
- Azure OpenAI deployment in `dev` (or AOAI-compatible endpoint) — provision in this sprint if not already.

---

## 7. Risks & Mitigations

| Risk | Mitigation |
|------|------------|
| Framework lock-in (Agent Framework still evolving) | Keep prompt + tool layer framework-agnostic; isolate framework calls behind an `AgentRuntime` adapter. |
| Tracing overhead masks real bugs | Sample at 100 % in `dev`, drop to 10 % later; log raw payloads for failed runs only. |
| Eval flakiness from LLM non-determinism | Use temperature 0 in evals; assert substring/structure, not exact match. |

---

## 8. Exit Criteria

- [ ] All user stories done.
- [ ] M2 demo executed (see below).
- [ ] Eval smoke task passes in CI.
- [ ] ADR-0005 merged.

---

## 9. Demo Script (M2)

1. Run `agentic-devops "echo 'Sprint 1 complete'"` → agent prints the response.
2. Open App Insights → show the trace with two spans (`plan`, `echo_tool`).
3. Open Cosmos DB Data Explorer → show the persisted run document, partition key, correct fields.
4. Run `agentic-devops "echo 'demo'" --dry-run` → mutating tool prints planned write, **does not** persist.
5. Trigger CI on a PR → `eval.yml` runs the smoke task and posts a green check.

---

## 10. Related Documents

- [sprints/SPRINT_PLAN.md](./SPRINT_PLAN.md)
- [docs/AI.md](../docs/AI.md)
- [docs/DATA.md](../docs/DATA.md)
- [docs/ARCHITECTURE.md](../docs/ARCHITECTURE.md)
