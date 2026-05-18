# Test Strategy

| Field | Value |
|-------|-------|
| **Version** | 2.0.0 |
| **Date** | 2026-05-18 |
| **Author** | Urs Rüegg |
| **Status** | Draft |
| **Previous Version** | 1.0.0 (pytest/vitest test pyramid with unit, integration, contract, eval, smoke layers and ≥ 80 % line coverage on changed code); 2.0.0 retires that pyramid per [ADR-0002](adr/0002-runtime-is-github-copilot-coding-agent.md) — there is no platform code to unit-test. Strategy collapses to (a) Markdown lint + link check, (b) Bicep validate + what-if for UC1 outputs, (c) golden-task fixture replay for prompt/MCP changes, (d) security scans. |

> **Related**: [ADR-0002](adr/0002-runtime-is-github-copilot-coding-agent.md),
> [AI.md](AI.md) §6, [ALM_PLAN.md](ALM_PLAN.md) §2.

## Table of Contents

1. [Test Surfaces](#1-test-surfaces)
2. [Markdown & Link Hygiene](#2-markdown--link-hygiene)
3. [Bicep Validation (UC1 outputs)](#3-bicep-validation-uc1-outputs)
4. [Golden-Task Fixtures](#4-golden-task-fixtures)
5. [Security Tests](#5-security-tests)
6. [CI Enforcement](#6-ci-enforcement)
7. [Open Questions](#7-open-questions)

## 1. Test Surfaces

There is no application binary. The artefacts that need validation are:

| Surface | What is tested | Tool |
|---------|----------------|------|
| Markdown docs | Lint rules + cross-doc links resolve | `markdownlint-cli2`, `markdown-link-check` |
| Bicep templates (UC1 outputs) under `infra/**` | Build cleanly + `what-if` against a customer sandbox | `az bicep build`, `az deployment ... what-if` |
| Agent prompts under `agents/**/AGENT.md` | Behave per golden-task fixtures | Optional `eval-goldens.yml` workflow |
| MCP allow-list `.github/copilot/mcp.json` | CODEOWNERS-gated; covered by a representative golden task | PR review |
| Workflows under `.github/workflows/**` | YAML lint + action-pinning + secret hygiene | `actionlint`, `gitleaks` |
| Security posture | CodeQL, secret scan, dependency scan | `security.yml` |

No `pytest`, no `vitest`, no unit/integration test pyramid in this repo today.
If a future use case introduces source code, it must bring its own test
harness and update this section in the same PR (per
[`.github/copilot-instructions.md` §3](../.github/copilot-instructions.md#3-coding-conventions)).

## 2. Markdown & Link Hygiene

- Every doc edit must pass `markdownlint-cli2 "**/*.md" "#node_modules"`.
- `markdown-link-check` must pass on `docs/**/*.md`, `sprints/*.md`, and
  `.github/*.md`. Cross-doc anchors must resolve (this is how ADR-0002's
  link into [AI.md §2.1](AI.md#21-model-provider-abstraction-not-applicable-at-runtime)
  is verified).

## 3. Bicep Validation (UC1 outputs)

- Every `.bicep` under `infra/` must build cleanly with `az bicep build`.
- A `what-if` against the customer sandbox (`iac-validate.yml`) must succeed
  on any PR that touches `infra/**`.
- Mandatory tags on every resource: `env`, `owner`, `costCenter`, `workload`.
- Use Azure Verified Modules (AVM) where available.

## 4. Golden-Task Fixtures

The primary correctness test for any agent change is a **golden-task
fixture replay**:

- Path: `agents/<name>/golden-tasks.md` (preferred) or `evals/<name>/*.md`.
- **Fixture shape** (Markdown, fixed structure):
  - **Input issue body** — exact issue body the agent receives.
  - **Expected MCP tool calls** — ordered or set, with input shapes.
  - **Expected PR / comment shape** — required sections, idempotency markers,
    FR/NFR IDs in the description.
  - **Forbidden behaviors** — things the agent must not do (e.g., fire a
    deploy tool without approval).
  - Front-matter `requirement:` key linking the fixture to one or more
    `FR-*` / `NFR-*` IDs from [PRD.md](PRD.md).
- **Coverage**: every agent has at least one happy-path fixture and one
  failure-mode fixture before its sprint exits.
- **Eval gate**: any change to `agents/**`, `.github/copilot/mcp.json`, or
  `evals/**` must update or add a fixture and reference the replay in the
  PR description.
- **Replay mechanism**: optional `eval-goldens.yml` GitHub Actions workflow
  runs the fixture set against the Copilot coding agent. Manual replay is
  acceptable for fixtures the workflow does not yet cover.
- **Metrics** tracked per fixture run:
  - Scope adherence (no out-of-scope edits / tool calls).
  - Policy-violation rate (refusal-rule compliance).
  - Latency (issue creation → draft PR opened).
  - Idempotency (re-running on the same input produces the same artefact).

Flaky fixtures are not tolerated. Fix the prompt or pin the fixture.

## 5. Security Tests

- **CodeQL** on every PR (scoped to YAML and any future code).
- **Secret scanning** enabled at repo level; agents must redact token-like
  strings before posting comments (see [SECURITY.md](SECURITY.md) §2).
- **Dependency scanning** (Dependabot) on `package.json` (if introduced) and
  GitHub Actions versions.
- **IaC scanning** on `infra/**` (psrule / checkov, configurable).
- **MCP allow-list review** on every change to `.github/copilot/mcp.json`.

## 6. CI Enforcement

- All required checks (Markdown lint, link check, Bicep build/validate where
  applicable, security scan, golden-task replay where applicable) must pass
  before merge.
- See [ALM_PLAN.md §2](ALM_PLAN.md#2-ci-pipelines) for the workflow
  inventory.

## 7. Open Questions

- Whether `eval-goldens.yml` should block merge on fixture failure, or post
  results and let a human decide. Resolved in Sprint 1 once the fixture
  format is finalised.

