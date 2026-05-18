# Artefact Catalogue

| Field | Value |
|-------|-------|
| **Version** | 1.1.0 |
| **Date** | 2026-05-18 |
| **Author** | Urs Rüegg |
| **Status** | Draft |
| **Previous Version** | 1.0.0 (initial release); 1.1.0 updates the sub-component table and reading order for the **GitHub Copilot coding agent runtime** per [ADR-0002](adr/0002-runtime-is-github-copilot-coding-agent.md) (agents are Markdown + MCP config; `tools/` and `api/` are not present). |

> **Single entry point** for all Agentic DevOps Platform documentation.
> Read this file first, then drill into the document relevant to your task.

## Table of Contents

1. [Solution-Level Documents](#solution-level-documents)
2. [Sub-Component Documents](#sub-component-documents-populated-as-components-are-added)
3. [Reading Order by Task](#reading-order-by-task)

## Solution-Level Documents

| Document | Purpose | Read before changing... |
|----------|---------|------------------------|
| [SOLUTION_OVERVIEW.md](SOLUTION_OVERVIEW.md) | End-to-end solution overview, use cases, governance, roadmap | Any cross-cutting initiative or onboarding |
| [PRD.md](PRD.md) | Product requirements: personas, user journeys, FR/NFR catalogue with stable IDs, traceability matrix | Any scope/feature/requirement change; ALWAYS read before writing user stories or PRs |
| [ARCHITECTURE.md](ARCHITECTURE.md) | System architecture (Copilot coding agent + MCP + repo assets), agent contracts, integrations | Service boundaries, agent contracts, infra topology |
| [AI.md](AI.md) | Responsible AI guidelines, agent governance, model-provider note, prompt patterns | Agent prompts, refusal rules, RAI compliance |
| [SECURITY.md](SECURITY.md) | Zero Trust, identity (Copilot coding-agent + WIF/OBO), secrets, MCP allow-list | Auth flows, MCP servers, RBAC, secrets |
| [DATA.md](DATA.md) | Agent memory (repo + GitHub-native artefacts), retention | Data flow, retention, PII handling |
| [INFRASTRUCTURE.md](INFRASTRUCTURE.md) | UC1 *output* Bicep template library, customer-side environments | Bicep modules, customer landing zones |
| [ALM_PLAN.md](ALM_PLAN.md) | CI workflows (markdownlint, link check, Bicep validate, security scan, optional eval replay) | Workflows, release process, rollback |
| [TEST.md](TEST.md) | Test surfaces (Markdown lint, Bicep validate, golden-task fixtures, security scans) | Test patterns, eval gates |
| [adr/](adr/) | Architecture Decision Records | Any cross-cutting change |
| [../sprints/](../sprints/) | Sprint plan and per-sprint deliverables for implementing the platform | Sprint planning, scope changes, delivery tracking |

## Sub-Component Documents *(populated as components are added)*

| Component | Folder | Asset Type | Status |
|-----------|--------|------------|--------|
| Agent registry | `AGENTS.md` (root) | Markdown | Planned |
| Repo-wide Copilot guidance | `.github/copilot-instructions.md` | Markdown | Present |
| MCP allow-list | `.github/copilot/mcp.json` | JSON | Planned |
| Issue templates | `.github/ISSUE_TEMPLATE/` | YAML | Planned |
| PR template | `.github/PULL_REQUEST_TEMPLATE.md` | Markdown | Present |
| Workflows (CI / IaC validate / security / nightly / webhook receiver / eval) | `.github/workflows/` | GitHub Actions YAML | Planned |
| Agent prompt files | `agents/<name>/AGENT.md` | Markdown | Planned |
| Golden-task fixtures | `agents/<name>/golden-tasks.md` / `evals/<name>/*.md` | Markdown | Planned |
| UC1 output infrastructure (Bicep) | `infra/` | Bicep | Planned |
| Sample fixtures | `samples/` | JSON / Markdown | Planned |

Note: There is no `tools/` or `api/` folder. Tools are MCP servers (external);
the "API" surface is the GitHub-native PR/issue surface plus the MCP tool
surface.

## Reading Order by Task

| If you are... | Read in this order |
|---------------|-------------------|
| **Onboarding to the project** | `SOLUTION_OVERVIEW.md` → `PRD.md` → `ARCHITECTURE.md` → `SECURITY.md` → `adr/0002-runtime-is-github-copilot-coding-agent.md` |
| **Adding or changing a feature** | `PRD.md` (find/add requirement IDs) → relevant sprint doc → `ARCHITECTURE.md` / `SECURITY.md` |
| **Adding or modifying an agent prompt** | `AI.md` → `ARCHITECTURE.md` §3 → `TEST.md` §4 (golden tasks) → `AGENTS.md` |
| **Adding a new MCP server to the allow-list** | `SECURITY.md` §4 → `AI.md` → `.github/copilot/mcp.json` → `agents/<name>/golden-tasks.md` |
| **Adding or changing UC1 output infrastructure** | `INFRASTRUCTURE.md` → `ALM_PLAN.md` → `SECURITY.md` §8 |
| **Changing CI workflows** | `ALM_PLAN.md` → `SECURITY.md` → `TEST.md` |
| **Recording a cross-cutting decision** | `adr/` (use the template) |
| **Planning or delivering a sprint** | `../sprints/README.md` → `../sprints/SPRINT_PLAN.md` → relevant `sprint-NN-*.md` |

