# 0002. Runtime is GitHub Copilot Coding Agent

- **Status**: Accepted
- **Date**: 2026-05-18
- **Deciders**: Platform team (Urs Rüegg)
- **Tags**: `runtime`, `architecture`, `agents`, `process`

## Context

The earlier draft of this platform assumed a custom Python agent runtime
(Microsoft Agent Framework / Semantic Kernel) hosted on Azure Container Apps
or Azure Functions, persisting traces to Azure Cosmos DB and emitting
OpenTelemetry to Application Insights — broadly the stack implied by
[`docs/ARCHITECTURE.md`](../ARCHITECTURE.md) v1.0.0,
[`docs/DATA.md`](../DATA.md) v1.0.0, and
[`sprints/sprint-01-orchestrator-mvp.md`](../../sprints/sprint-01-orchestrator-mvp.md) v1.0.0.

That stack delivers the use cases in the [PRD](../PRD.md), but it
introduces non-trivial runtime infrastructure and operational cost before
any business value is demonstrated.

Two things have changed since v1.0.0 of those docs:

1. **GitHub Copilot coding agent** has matured to where it can act as a
   first-class agent runtime: it accepts issues, opens branches and PRs,
   runs MCP tools (including the Azure MCP server, the GitHub MCP server,
   and the Azure DevOps MCP server), respects per-repo instructions
   (`AGENTS.md`, `.github/copilot-instructions.md`), and exposes its run
   history via GitHub UI and audit log.
2. The platform owner has stated the platform should be implemented as a
   **GitHub Copilot coding agent inside this repository** — *not* as a
   bespoke Python service — so that the use cases in the PRD can be proven
   with zero custom runtime infrastructure.

This decision must be recorded before cascading changes through the rest of
the documentation, because per
[`/.github/copilot-instructions.md` §9](../../.github/copilot-instructions.md#9-document-versioning),
any **MAJOR** doc bump must be backed by an ADR.

## Decision

**The runtime for every agent in this platform is GitHub Copilot coding
agent, configured by repository assets in this repo.**

Concretely:

| Concern | Realization |
|---------|-------------|
| **Agent runtime host** | GitHub Copilot coding agent (managed by GitHub). |
| **LLM / model selection** | Whatever model GitHub Copilot uses. The platform does not select, deploy, or manage a model. See *Consequences → Q3 superseded*. |
| **Agent definitions** | Markdown prompt files under `agents/<agent-name>/` plus a top-level `AGENTS.md` and `.github/copilot-instructions.md` (already exists). |
| **Agent invocation** | GitHub issues (via `ISSUE_TEMPLATE/` templates), `@copilot` mentions on issues/PRs, or `workflow_dispatch` workflows. |
| **Sub-agents / orchestration** | Issue-driven hand-off (one agent's PR or comment creates the next agent's issue) and explicit sub-agent prompts. No Python orchestrator process. |
| **Tools** | MCP servers configured per repo: Azure MCP, Azure DevOps MCP, GitHub MCP, WorkIQ MCP. Tool contracts are MCP server schemas plus the side-effect/confirm policy in `AGENTS.md`. |
| **External targets** | UC1 outputs PRs to **Azure DevOps Repos** (Bicep); UC3 comments on **Azure DevOps PRs**; UC2 scans **Azure subscriptions** read-only. All via MCP servers. Triggers from ADO arrive via ADO Service Hooks that file a GitHub issue. |
| **Traces / audit** | GitHub Copilot coding-agent run history + GitHub issue/PR threads + GitHub audit log. No Azure Cosmos DB and no OpenTelemetry/Application Insights at the platform runtime layer. |
| **Memory** | The repository itself: AGENTS.md, prompt files, ADRs, PRD, sprint docs, sample fixtures, golden tasks. Plus issue/PR history. |
| **Evals** | Markdown golden-task fixtures under `evals/` plus optional Copilot Eval workflows. No `pytest` harness in this repo. |
| **Identity** | The Copilot coding agent acts under its GitHub-provided identity. Outbound MCP calls into Azure/ADO authenticate via Entra (OBO when human-triggered; managed identity / federated credential when scheduled). |
| **CI/CD** | GitHub Actions: markdown lint, Bicep build/validate (for UC1 output templates), security scans, optional eval workflows. No agent build/deploy pipelines. |
| **Azure infrastructure for the platform** | None. The only Azure resources this repo touches are the *targets* the agents act on (customer subscriptions in UC1, ADO Repos in UC1/UC3, the read-only scanned subscriptions in UC2). |

The PRD's functional requirements (FR-UC1-*, FR-UC2-*, FR-UC3-*, FR-PLT-*)
remain in force — their **intent is unchanged**. The wording of a small
number of FRs that named a specific technology (Cosmos DB, OpenTelemetry,
Pydantic) is being made technology-neutral in a MINOR PRD bump alongside
this ADR; no FR/NFR ID is renamed or removed.

## Alternatives Considered

- **A. Bespoke Python agent runtime on Azure Container Apps + Cosmos DB + AOAI.**
  Highest control, full ownership of the stack. **Rejected** for v1: months
  of runtime/IaC work before any UC delivers value; ongoing operations cost;
  duplicates capabilities Copilot now provides natively.
- **B. Microsoft Foundry Agent Service-hosted agents.** Strong fit for
  hosted-agent scenarios, but the platform owner does not want a Foundry-hosted
  runtime at this stage and prefers the GitHub-native loop (issue → PR) as the
  human-in-the-loop control point. Kept as a future option (see *Consequences*).
- **C. Hybrid (Copilot for some agents, Python for others).** **Rejected**
  for v1: introduces two runtimes simultaneously with no clear use-case
  forcing function.

## Consequences

### Positive
- Zero platform-runtime Azure infrastructure to provision, secure, and
  operate. Sprint 0's IaC scope collapses dramatically.
- Human-in-the-loop is **structural**: every agent action surfaces as an
  issue, PR, or comment.
- Audit trail is GitHub-native (issue/PR/branch history + audit log) and
  immediately credible to security and compliance reviewers.
- Fastest path to demoing UC1/UC2/UC3 end-to-end.
- Aligns with the existing `.github/copilot-instructions.md` and Conventional
  Commits / single-`main`-branch model already adopted in
  [`/.github/copilot-instructions.md`](../../.github/copilot-instructions.md).

### Negative
- **Model is not selectable.** GitHub Copilot picks the model. This
  **supersedes** [`sprints/SPRINT_PLAN.md` §9 Q3](../../sprints/SPRINT_PLAN.md#9-open-questions--resolutions)
  ("model-independent until pilot scale justifies a choice") — there is no
  longer a model-provider abstraction to maintain at the runtime layer. The
  guidance in [`docs/AI.md` §2.1](../AI.md#21-model-provider-abstraction-mandatory)
  is reduced to a forward-looking note for any future code.
- Dependency on GitHub Copilot coding-agent feature evolution, rate limits,
  and MCP support. Mitigated by keeping all agent definitions as plain
  Markdown + MCP server configs that could be re-hosted on a different
  agent runtime (e.g., Foundry, custom Python) if needed.
- No native sub-second telemetry / OpenTelemetry export. Mitigation: rely
  on GitHub audit log + Copilot run history; pull into an external store
  only if a future requirement demands it.
- Evals are golden-task Markdown fixtures plus manual PR review (and
  optional Copilot Eval workflows), not a `pytest` harness with eval
  metrics emitted to App Insights. Mitigation: golden tasks live in
  `evals/`, are version-controlled, and any agent-definition change must
  reference them in the PR.
- Scheduled triggers (UC2 nightly drift) require a GitHub Actions
  `schedule` workflow that opens an issue the coding agent picks up
  (Copilot itself does not run on cron). Documented in
  [`sprints/sprint-05-uc2-drift-detection.md`](../../sprints/sprint-05-uc2-drift-detection.md).
- Webhook-driven triggers (UC3 ADO PR events) require an ADO Service Hook
  that files a GitHub issue the coding agent picks up. Documented in
  [`sprints/sprint-04-uc3-pr-review.md`](../../sprints/sprint-04-uc3-pr-review.md).

### Risks and Follow-ups
- **R1 — Copilot rate limits or feature regressions stall a use case.**
  Mitigation: instrumentation is via repo metrics (issue cycle time, agent
  PR throughput); fallback path is to lift any single agent to a custom
  runtime without rewriting the prompt/tool definitions.
- **R2 — Sensitive operations (deploy/delete) executed without explicit
  human confirmation.** Mitigation: `AGENTS.md` enforces the
  `side_effects ∈ {read, write, deploy, delete}` taxonomy with a strict
  rule that `deploy`/`delete` require an explicit human approval comment
  before the agent calls the corresponding MCP tool. Reinforced in PR
  template and in per-agent prompts.
- **R3 — MCP server allow-list drift.** Mitigation: the set of MCP servers
  enabled for this repo is checked into `.github/copilot/mcp.json`
  *(introduced in Sprint 0)*; changes go through a PR with mandatory
  reviewer.

## Supersedes
- None directly. This ADR **does not** rename, retire, or remove any
  PRD FR/NFR.

## Superseded by
- None.

## Related
- [`/.github/copilot-instructions.md`](../../.github/copilot-instructions.md) — runtime conventions and PR contracts.
- [`docs/PRD.md`](../PRD.md) — functional/non-functional requirements (IDs preserved; wording made technology-neutral where it named Cosmos DB / OpenTelemetry / Pydantic).
- [`docs/ARCHITECTURE.md`](../ARCHITECTURE.md) — rewritten to reflect this runtime (MAJOR bump).
- [`docs/DATA.md`](../DATA.md) — rewritten: repo + GitHub history is the agent memory; Cosmos DB removed from the platform runtime (MAJOR bump).
- [`docs/INFRASTRUCTURE.md`](../INFRASTRUCTURE.md) — rewritten: no platform-runtime Azure resources (MAJOR bump).
- [`docs/AI.md`](../AI.md) §2.1 — model-provider abstraction marked not-applicable at runtime (MINOR bump).
- [`docs/ALM_PLAN.md`](../ALM_PLAN.md) — CI scope reduced (MAJOR bump).
- [`sprints/SPRINT_PLAN.md`](../../sprints/SPRINT_PLAN.md) §9 — Q3 marked Superseded by this ADR (MAJOR bump).
- [`sprints/sprint-01-orchestrator-mvp.md`](../../sprints/sprint-01-orchestrator-mvp.md) — fully rewritten as "Copilot Coding Agent MVP" (MAJOR bump).
