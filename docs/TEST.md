# Test Strategy

| Field | Value |
|-------|-------|
| **Version** | 1.0 |
| **Date** | 2026-05-18 |
| **Author** | Urs Rüegg |
| **Status** | Draft |
| **Previous Version** | — (initial release) |

> **Related**: [AI.md](AI.md), [ALM_PLAN.md](ALM_PLAN.md).

## Table of Contents

1. [Test Pyramid](#1-test-pyramid)
2. [Coverage Targets](#2-coverage-targets)
3. [Unit Tests](#3-unit-tests)
4. [Integration Tests](#4-integration-tests)
5. [Agent Evaluations (`evals/`)](#5-agent-evaluations-evals)
6. [Contract Tests for Tools](#6-contract-tests-for-tools)
7. [Security Tests](#7-security-tests)
8. [CI Enforcement](#8-ci-enforcement)
9. [Open Questions](#9-open-questions)

## 1. Test Pyramid

| Layer | Tooling | Scope | Owners |
|-------|---------|-------|--------|
| Unit | `pytest` / `vitest` | Pure functions, parsers, schema validation | Component owner |
| Integration | `pytest` + mocked Azure SDK / HTTPX MockTransport | Tool adapters, MCP wrappers, Cosmos repository | Component owner |
| Contract | JSON Schema validation | Tool input/output schemas | Tool owner |
| Agent evaluations | `evals/` harness | End-to-end agent behavior on golden tasks | Agent owner |
| Smoke / post-deploy | Pipeline step | Health endpoint + 1 happy-path agent run | SRE |

## 2. Coverage Targets
- **Changed-file coverage**: ≥ 80 % line coverage on new code.
- **PRs may not decrease overall coverage.**
- Coverage on generated code is not chased.

## 3. Unit Tests
- Co-located under `tests/` *(planned)*.
- Mock external services: Azure SDK clients, HTTP, Cosmos DB, Entra.
- Follow **Arrange-Act-Assert**.
- No flaky tests — fix or remove.

## 4. Integration Tests
- Required for **every new agent tool / skill**.
- Cover the happy path + at least one failure mode.
- Use ephemeral Cosmos DB Emulator for data layer tests where feasible.

## 5. Agent Evaluations (`evals/`)
- **Golden tasks** per agent (≥ 20 each).
- Stored as YAML/JSON fixtures with expected outputs or assertions.
- Metrics tracked per run:
  - Success rate
  - Scope adherence (no out-of-scope file edits / tool calls)
  - Policy-violation rate
  - Latency (p50/p95)
  - Cost (USD per task)
- **Eval gate**: any prompt, tool-contract, or control-flow change must run
  evals and attach results to the PR.
- Trend dashboard: see [AI.md](AI.md) §6.

## 6. Contract Tests for Tools
- Each tool ships a JSON Schema for input and output.
- Schemas validated at build time and at runtime in dev/test.

## 7. Security Tests
- CodeQL on every PR.
- Dependency scanning (Dependabot or equivalent).
- Secret scanning enabled at repo level.
- IaC scanning on `infra/**` changes.

## 8. CI Enforcement
- All tests + evals must pass in CI before merge.
- See [ALM_PLAN.md](ALM_PLAN.md) §5 for quality gates.

## 9. Open Questions
- TBD
