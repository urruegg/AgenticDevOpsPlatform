# Security

| Field | Value |
|-------|-------|
| **Version** | 1.0.0 |
| **Date** | 2026-05-18 |
| **Author** | Urs Rüegg |
| **Status** | Draft |
| **Previous Version** | — (initial release) |

> **Related**: [SOLUTION_OVERVIEW.md](SOLUTION_OVERVIEW.md) §6 Governance & Compliance.

## Table of Contents

1. [Threat Model](#1-threat-model)
2. [Identity & Access](#2-identity--access)
3. [Secrets Management](#3-secrets-management)
4. [Network Security](#4-network-security)
5. [Application Security](#5-application-security)
6. [Auditing & Non-Repudiation](#6-auditing--non-repudiation)
7. [Conditional Access & Risk](#7-conditional-access--risk)
8. [Destructive Actions Policy](#8-destructive-actions-policy)
9. [Open Questions](#9-open-questions)

## 1. Threat Model
*Identify assets, actors, threats, and mitigations. STRIDE per agent and per
external integration.*

| Asset | Threat | Mitigation |
|-------|--------|------------|
| Agent identity / token | Theft, misuse | Entra Agent ID, Conditional Access, short-lived tokens |
| Source code in ADO | Unauthorized modification | Branch protection, PR review, agent has no merge rights |
| Azure subscription | Misconfiguration / non-compliant deploy | Azure Policy, staging validation, Bicep `what-if` |
| Secrets | Leakage in logs / prompts | Key Vault, prompt filtering, no secrets in agent context |
| M365 data via WorkIQ | Over-broad access | Permission-trimmed retrieval, OBO flow |

## 2. Identity & Access

### 2.1 Entra ID Topology
- **Tenant model**: workforce tenant for internal users and service agents.
  External tenant (CIAM) if/when public surfaces are added.
- **Agent identities**: managed via Entra Agent ID. Each agent has its own
  identity, owner, and lifecycle.

### 2.2 OBO vs. Service Identity
| Pattern | When to use | Identity |
|---------|-------------|----------|
| OBO (delegated) | User-triggered workflows (UC1 initiated by SA) | Acts as the requesting user |
| Service identity (non-OBO) | Autonomous workflows (PR review, drift scan) | Dedicated agent identity with narrow scope |

### 2.3 RBAC
*Document role assignments per agent (least privilege).*

| Agent | ADO Permissions | Azure Permissions | Other |
|-------|-----------------|--------------------|-------|
| Spec Parser & Deployment | Repo contributor (feature branches), Pipeline run | Reader on staging sub; Deploy via pipeline service connection | — |
| Drift Analyzer | Repo reader | Reader on target subscription | — |
| PR Review | Repo reader, PR comment | None | Boards read |

## 3. Secrets Management
- **All secrets in Azure Key Vault**; referenced via App Service / Container
  Apps Key Vault references or managed identity.
- **No secrets in code, config files, or prompts.**
- **ADO variable groups** linked to Key Vault for pipeline secrets.

## 4. Network Security
- Private endpoints for Key Vault, Cosmos DB, Storage in production.
- CORS allow-lists per environment; never `*`.
- Egress controlled via NSG or Azure Firewall in hub-spoke topology (TBD).

## 5. Application Security
- Validate and sanitise all agent tool inputs — **treat LLM output as untrusted**.
- Parameterise all queries (KQL, SQL, Dataverse, Cosmos SQL).
- Enforce HTTPS / TLS 1.2+ on all endpoints.
- Apply OWASP Top 10 checklist on every PR.

## 6. Auditing & Non-Repudiation
- **ADO native telemetry** for repo/pipeline/board actions, attributed to the
  acting identity (user or agent).
- **Application Insights** for agent turn telemetry (inputs, tools called,
  outputs, cost, latency).
- **Log Analytics workspace** for centralized retention (target retention TBD).
- **Agent 365** integration for centralized policy enforcement and lifecycle.

## 7. Conditional Access & Risk
- Conditional Access policies applied to all agent identities.
- Risk-based sign-in policies for human operators triggering agents.
- Anomaly detection on agent behavior (sudden scope expansion, off-hours runs).

## 8. Destructive Actions Policy
- **No destructive action without explicit human confirmation.** This applies
  to: delete, drop, force-push, scale-to-zero, `terraform destroy`, `az ... delete`.
- Agents must produce a dry-run / plan before any mutating call.
- See [.github/copilot-instructions.md](../.github/copilot-instructions.md) §4.

## 9. Open Questions
- TBD
