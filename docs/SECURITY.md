# Security

| Field | Value |
|-------|-------|
| **Version** | 2.0.0 |
| **Date** | 2026-05-18 |
| **Author** | Urs Rüegg |
| **Status** | Draft |
| **Previous Version** | 1.0.0 (Entra Agent ID as the platform's primary agent-identity construct; Cosmos / KV / App Insights as platform-runtime trust boundaries); 2.0.0 retires that runtime framing per [ADR-0002](adr/0002-runtime-is-github-copilot-coding-agent.md). Agent identity in this repo is the **GitHub Copilot coding-agent identity**; outbound calls to Azure / ADO authenticate via **Workload Identity Federation** (OIDC) or **OBO** through MCP servers. Entra Agent ID is repositioned as a forward-looking pattern for any future non-Copilot code, *and* as the construct UC1 may provision inside the customer's landing zone. |

> **Related**: [ADR-0002](adr/0002-runtime-is-github-copilot-coding-agent.md),
> [SOLUTION_OVERVIEW.md](SOLUTION_OVERVIEW.md) §6,
> [`.github/copilot-instructions.md` §4](../.github/copilot-instructions.md#4-security).

## Table of Contents

1. [Threat Model](#1-threat-model)
2. [Identity & Access](#2-identity--access)
3. [Secrets Management](#3-secrets-management)
4. [MCP Server Allow-List](#4-mcp-server-allow-list)
5. [Application Security](#5-application-security)
6. [Auditing & Non-Repudiation](#6-auditing--non-repudiation)
7. [Destructive Actions Policy](#7-destructive-actions-policy)
8. [UC1 Output Networking & Identity (customer side)](#8-uc1-output-networking--identity-customer-side)
9. [Open Questions](#9-open-questions)

## 1. Threat Model

| Asset | Threat | Mitigation |
|-------|--------|------------|
| GitHub Copilot coding-agent run | Prompt injection from MCP output / issue body | Refusal rules in `AGENTS.md` + per-agent prompt; treat every MCP/LLM value as untrusted; redact token-like strings before posting comments |
| MCP allow-list (`.github/copilot/mcp.json`) | Unauthorised server addition that broadens blast radius | CODEOWNERS-gated PR; documented purpose and required permissions; golden-task exercising the new server |
| Federated credential to Azure / ADO | Misuse via MCP | Least-privilege RBAC on the MCP-side principal; short-lived OIDC tokens; no long-lived secrets |
| Repository (prompts, AGENTS.md, Bicep templates) | Tampering or unauthorised merge | Branch protection on `main`; required reviewers on `agents/**`, `.github/copilot/**`, `infra/**`; signed commits where supported |
| ADO PR comments (UC3) | Spoofed PR review or impersonation | PR comment includes idempotency marker `<!-- agentic-devops:pr-review -->`; service principal scoped to PR-comment only |
| Azure subscription (UC1 / UC2 target) | Non-compliant deploy or unauthorised mutation | Required `what-if` before `create`; human "approved-to-apply" comment gates deploy/delete; Azure Policy on customer side |
| M365 data via WorkIQ | Over-broad data exposure | Permission-trimmed retrieval enforced by WorkIQ MCP; OBO flow for human-triggered runs |
| Webhook receiver (UC3) | Forged ADO Service Hook payload | HMAC signature validation in `uc3-webhook-receiver.yml`; IP allowlist where feasible; short-lived inbound token |

## 2. Identity & Access

### 2.1 Inside this repo

- All agent execution runs under the **GitHub Copilot coding-agent identity**.
  This is the identity GitHub provides; the platform does not register or
  manage it.
- Human invocation (issue authoring, `@copilot` mentions, manual
  `workflow_dispatch`, PR approval comments) runs under the human's GitHub
  identity, governed by GitHub org SSO + Entra Conditional Access at the SSO
  boundary.
- CODEOWNERS gates apply to `AGENTS.md`, `agents/**`, `.github/copilot/**`,
  `infra/**`, and `docs/adr/**`.

### 2.2 Outbound calls via MCP

| Target | Pattern | Identity | Notes |
|--------|---------|----------|-------|
| Azure (UC1 deploy / UC2 read) | **Workload Identity Federation** (OIDC from GitHub Actions / Copilot) | Customer-side service principal with least-privilege Azure RBAC | No long-lived secrets in the repo. Scoped per customer environment, not per platform environment. |
| Azure (human-triggered UC1) | **OBO** | Acts on behalf of the requesting SA | Cannot exceed the SA's Azure RBAC. |
| Azure DevOps (UC1 / UC3) | OIDC → ADO service connection, or short-lived PAT-equivalent via MCP | ADO service principal with feature-branch / PR-comment scope only | Cannot merge; cannot push to `main`. |
| GitHub MCP | GitHub App / fine-grained PAT scoped to this repo | Scoped to read issues/PRs and write comments/branches | Used by Orchestrator. |
| WorkIQ MCP | OBO | Acts on behalf of the requesting user | Honours M365 permission boundaries. |

### 2.3 Entra Agent ID (forward-looking)

Entra Agent ID is **not** the runtime identity inside this repo (the runtime
is Copilot coding agent — ADR-0002). Entra Agent ID re-enters scope in two
forward-looking ways:

- **UC1 output**: the customer's landing zone may provision agents that act
  inside the customer's tenant under Entra Agent IDs. The Bicep templates in
  `infra/` are the home for that pattern.
- **Future non-Copilot code in this repo**: if a use case introduces a helper
  service, it must run under a registered Entra Agent ID. Adoption is gated
  by an ADR at that point.

## 3. Secrets Management

- **GitHub Actions secrets** for any value a workflow needs (e.g., the ADO
  Service Hook HMAC). Federated OIDC is preferred over secrets wherever
  possible.
- **No connection strings, API keys, or PATs** committed to the repo or
  pasted into prompts / PR descriptions. Agents must redact token-like
  strings before posting any comment.
- **Azure Key Vault** appears only inside Bicep templates under `infra/`
  (UC1 outputs); it secures the *customer's* application, not the platform.

## 4. MCP Server Allow-List

- All MCP usage goes through `.github/copilot/mcp.json` (the allow-list).
- Adding a server requires a CODEOWNERS-approved PR documenting:
  - **Purpose** (which use case, which agent).
  - **Required permissions** (Azure RBAC roles, ADO scopes, GitHub
    permissions on the MCP-side principal).
  - **Side-effect ceiling** (`read | write | deploy | delete`).
  - At least one golden-task fixture exercising a representative tool.
- MCP servers must be **version-pinned**; upgrades go through the same PR
  process with a golden-task replay.

## 5. Application Security

- Treat every value from an MCP tool or LLM output as **untrusted input**.
  Validate before passing to another tool, shell, KQL query, or Bicep parameter.
- Parameterise all queries (KQL, ADO query, Cosmos SQL inside UC1 outputs).
- Enforce HTTPS / TLS 1.2+ on every endpoint the agent talks to.
- Apply the **OWASP Top 10** lens during PR review on any committed script
  or Bicep module.

## 6. Auditing & Non-Repudiation

- **GitHub audit log** records every change to the repo, MCP allow-list,
  CODEOWNERS, branch protection rules, and team membership.
- **GitHub Copilot coding-agent run history** records every agent
  invocation, prompt, tool call, and produced artefact (in the GitHub UI).
- **Git history** of `agents/**`, `.github/copilot/**`, and `infra/**` is
  the immutable record of prompt/template evolution.
- **ADO activity log** captures every UC1 commit, PR open, PR comment, and
  pipeline trigger, attributed to the MCP-side principal.
- **Azure activity log** captures every UC1 deploy on the customer side.

Non-repudiation is achieved by tying every artefact to either the
Copilot coding-agent identity or the human who confirmed `approved-to-apply`.

## 7. Destructive Actions Policy

Applies to: `delete`, `drop`, force-push, scale-to-zero,
`terraform destroy`, `az ... delete`, ADO branch deletion, Cosmos container
drop — any operation whose side-effect ceiling is `deploy` or `delete`.

- Agent must produce a **what-if / plan first** and pause.
- Human must post an **explicit approval comment** containing the magic
  phrase `approved-to-apply` on the agent's draft PR or issue.
- Only then does the agent fire the mutating MCP tool call.
- See [`.github/copilot-instructions.md` §4](../.github/copilot-instructions.md#4-security).

## 8. UC1 Output Networking & Identity (customer side)

For the customer's landing zone (UC1 outputs):

- Private endpoints for Key Vault, Cosmos DB, Storage in `prod`.
- CORS allow-lists per environment; never `*`.
- Egress via NSG or Azure Firewall in hub-spoke topology where the spec
  requires it.
- Customer-side managed identities (or Entra Agent IDs) for any agentic
  workload the customer hosts inside the landing zone.

These rules apply to **the customer's** environment, not the platform.

## 9. Open Questions

- Final shape of HMAC validation in `uc3-webhook-receiver.yml` (Sprint 4).

