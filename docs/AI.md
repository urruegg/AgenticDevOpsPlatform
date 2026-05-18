# AI Governance & Responsible AI

| Field | Value |
|-------|-------|
| **Version** | 1.0 |
| **Date** | 2026-05-18 |
| **Author** | Urs Rüegg |
| **Status** | Draft |
| **Previous Version** | — (initial release) |

> **Related**: [SOLUTION_OVERVIEW.md](SOLUTION_OVERVIEW.md), [SECURITY.md](SECURITY.md).

## Table of Contents

1. [Responsible AI Principles](#1-responsible-ai-principles)
2. [Model Selection](#2-model-selection)
3. [Prompt Patterns](#3-prompt-patterns)
4. [Tool Contracts](#4-tool-contracts)
5. [Agent Memory & Traces](#5-agent-memory--traces)
6. [Evaluation Harness](#6-evaluation-harness)
7. [Human Oversight](#7-human-oversight)
8. [Content & Safety Filters](#8-content--safety-filters)
9. [Data Boundaries](#9-data-boundaries)
10. [Accountability](#10-accountability)
11. [Open Questions](#11-open-questions)

## 1. Responsible AI Principles
This platform aligns with **Microsoft's Responsible AI Standard**:
fairness, reliability & safety, privacy & security, inclusiveness,
transparency, accountability.

## 2. Model Selection

| Use Case | Recommended Model | Rationale |
|----------|-------------------|-----------|
| Orchestrator reasoning | TBD (e.g., GPT-4o / GPT-5) | High reasoning, tool-use quality |
| Spec parsing / structured extraction | TBD | Cost-efficient, structured output |
| PR review summarization | TBD | Long-context, cost-balanced |
| Drift analysis | TBD | Code-aware |

*Re-evaluate quarterly against Microsoft Foundry catalog.*

## 3. Prompt Patterns
- Use **system messages** for invariant instructions (identity, scope, refusal rules).
- Use **structured outputs (JSON schemas)** wherever the downstream consumer is code.
- Include **dry-run / plan stage** in every mutating agent's prompt before action.
- **Explicit refusal rules**: agent refuses destructive actions without human
  confirmation; refuses to operate outside scoped repositories / subscriptions.

## 4. Tool Contracts
Each tool exposed to an agent must declare:
- **Name**
- **Description** (LLM-readable, unambiguous)
- **Input schema** (JSON Schema)
- **Output schema** (JSON Schema)
- **Side effects** (read-only / mutating)
- **Required permissions** (Entra roles, ADO scopes, Azure RBAC)
- **Failure modes**

## 5. Agent Memory & Traces
- **Short-term context**: in-prompt only.
- **Long-term traces**: persisted to Cosmos DB / Application Insights — see
  [DATA.md](DATA.md).
- **Retention**: TBD (default 90 days, longer for compliance reviews).

## 6. Evaluation Harness
- Located at `evals/` *(planned)*.
- **Golden tasks** per agent: ≥ 20 representative scenarios with expected outputs.
- **Metrics**: success rate, scope adherence, policy-violation rate, latency, cost.
- **Eval gate**: any prompt, tool-contract, or control-flow change must run
  `evals/` and attach results to the PR.
- **Continuous monitoring**: nightly eval run with trend alerts.

## 7. Human Oversight
- Buddy-check / approval steps at every state-changing action.
- Agents output **artifacts (PRs, comments)** rather than direct mutations
  wherever possible.
- See [SOLUTION_OVERVIEW.md](SOLUTION_OVERVIEW.md) §3.6.

## 8. Content & Safety Filters
- Use Azure OpenAI / Foundry content filters; never disable in production.
- Log filtered responses with reason, redacted of PII.
- Jailbreak / prompt-injection detection on user-provided inputs.

## 9. Data Boundaries
- Agents only access data they are entitled to via their identity (OBO or
  service principal).
- **WorkIQ** access is permission-trimmed by design.
- No PII in prompts unless strictly required and logged with consent.

## 10. Accountability
- Each agent has a registered **owner** in Entra Agent ID.
- Owner is responsible for prompt quality, eval pass-rate, and incident response.

## 11. Open Questions
- TBD
