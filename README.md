# AgenticDevOpsPlatform
Agentic DevOps Platform Sample

| Field | Value |
|-------|-------|
| **Version** | 1.0.0 |
| **Date** | 2026-05-18 |
| **Author** | Urs Rüegg |
| **Status** | Draft |
| **Previous Version** | — (initial release) |

A reference design for an **enterprise-grade Agentic DevOps platform** that
orchestrates GitHub Copilot agents and WorkIQ to automate Azure DevOps
workflows — subscription provisioning, drift management, and pull-request
reviews — under strict identity, compliance, and human-in-the-loop governance.

## Table of Contents

1. [Documentation](#documentation)
2. [Contributing](#contributing)
3. [Status](#status)

## Documentation

Start with the **artefact catalogue** for the full map of documents:

- [docs/ARTEFACTS.md](docs/ARTEFACTS.md) — single entry point
- [docs/SOLUTION_OVERVIEW.md](docs/SOLUTION_OVERVIEW.md) — end-to-end solution overview, use cases, governance, roadmap
- [sprints/README.md](sprints/README.md) — sprint plan to implement the platform end-to-end

### Cross-cutting docs
| Topic | Document |
|-------|----------|
| Product requirements & traceability | [docs/PRD.md](docs/PRD.md) |
| System architecture | [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) |
| Responsible AI & agent governance | [docs/AI.md](docs/AI.md) |
| Security, identity, secrets | [docs/SECURITY.md](docs/SECURITY.md) |
| Data model & storage | [docs/DATA.md](docs/DATA.md) |
| Infrastructure (Bicep) | [docs/INFRASTRUCTURE.md](docs/INFRASTRUCTURE.md) |
| CI/CD & release | [docs/ALM_PLAN.md](docs/ALM_PLAN.md) |
| Test strategy & evals | [docs/TEST.md](docs/TEST.md) |
| Architecture decisions | [docs/adr/](docs/adr/) |

## Contributing

See [.github/copilot-instructions.md](.github/copilot-instructions.md) for
repo-wide conventions, scope guards, security rules, and PR contracts.

## Status

Early-stage sample. Folders such as `agents/`, `tools/`, `api/`, `infra/`,
`tests/`, and `evals/` are **planned** and will be populated as the platform
is built. See [docs/SOLUTION_OVERVIEW.md §8](docs/SOLUTION_OVERVIEW.md#8-phased-roadmap)
for the phased adoption roadmap and [sprints/SPRINT_PLAN.md](sprints/SPRINT_PLAN.md)
for the concrete sprint sequencing.
