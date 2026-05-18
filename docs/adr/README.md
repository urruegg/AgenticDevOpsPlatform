# Architecture Decision Records (ADRs)

| Field | Value |
|-------|-------|
| **Version** | 1.3.0 |
| **Date** | 2026-05-25 |
| **Author** | Urs Rüegg |
| **Status** | Draft |
| **Previous Version** | 1.0.0 (initial release); 1.1.0 added ADR-0002 to index; 1.2.0 added ADR-0003 (Bicep as IaC) and ADR-0004 (OIDC federation) as `Proposed` per Sprint 0 §3.1 Runtime Amendment; 1.3.0 marks ADR-0003 `Accepted` after Sprint 2 shipped the first UC1 Bicep output and adds ADR-0006 (WorkIQ MCP as the UC1 spec source) as `Accepted`. |

This folder contains lightweight Architecture Decision Records that capture
significant cross-cutting decisions for the Agentic DevOps Platform.

## Table of Contents

1. [Conventions](#conventions)
2. [Index](#index)

## Conventions
- **Filename**: `NNNN-short-title.md` where `NNNN` is a zero-padded sequence
  number (e.g., `0001-record-architecture-decisions.md`).
- **Status**: one of `Proposed`, `Accepted`, `Deprecated`, `Superseded`.
- **Template**: see [`0000-template.md`](0000-template.md).

## Index

| # | Title | Status | Date |
|---|-------|--------|------|
| 0001 | [Record Architecture Decisions](0001-record-architecture-decisions.md) | Accepted | 2026-05-18 |
| 0002 | [Runtime is GitHub Copilot Coding Agent](0002-runtime-is-github-copilot-coding-agent.md) | Accepted | 2026-05-18 |
| 0003 | [Bicep as the IaC language for UC1 output landing-zone templates](0003-bicep-as-iac.md) | Accepted | 2026-05-25 |
| 0004 | [OIDC federation for MCP-side service principals](0004-oidc-federation.md) | Proposed | 2026-05-18 |
| 0006 | [WorkIQ MCP as the UC1 spec source](0006-workiq-mcp-as-spec-source.md) | Accepted | 2026-05-25 |
