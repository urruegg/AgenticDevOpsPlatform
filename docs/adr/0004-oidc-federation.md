# 0004. OIDC federation for MCP-side service principals

- **Status**: Proposed
- **Date**: 2026-05-18
- **Deciders**: @urruegg
- **Tags**: `security`, `identity`, `mcp`

## Context

Per [ADR-0002 Runtime is GitHub Copilot coding agent](0002-runtime-is-github-copilot-coding-agent.md),
all outbound calls to Azure and Azure DevOps happen via MCP servers
(`azure-mcp`, `azure-devops-mcp`, `workiq-mcp`) invoked by the Copilot coding
agent. Those MCP servers need a credential to reach the target tenant. Two
modes are needed:

1. **Autonomous runs** (e.g., UC2 nightly scan): the agent acts without a
   human in the loop.
2. **Human-triggered runs** (e.g., UC1 build from a `uc1-build-subscription`
   issue): the human's identity must flow through to the target system so
   audit trails attribute the action to the human, not a shared service
   principal.

The platform must avoid long-lived secrets (PATs, client secrets) in the
repository, in GitHub Actions secrets, and in MCP server configuration.

## Decision

The platform uses **Workload Identity Federation (WIF)** for autonomous MCP
calls and **On-Behalf-Of (OBO)** for human-triggered MCP calls.

- **Autonomous**: each MCP server has a dedicated Entra service principal
  per environment. A federated credential trusts a specific
  `repository_dispatch` / `schedule` workflow identity in this repo
  (`urruegg/AgenticDevOpsPlatform`) for the `main` branch.
- **Human-triggered**: when an issue is opened from
  `ISSUE_TEMPLATE/uc{1,2,3}-*.yml`, the MCP server exchanges the human's
  Entra token (via OBO) for a token scoped to the target resource. The
  agent records the human's GitHub handle alongside the Azure / ADO upn in
  the resulting PR description so the audit chain is preserved.
- **No long-lived secrets**: PATs and client secrets are forbidden in
  `mcp.json`, GitHub Actions secrets, and Key Vault references owned by
  this platform. Customer landing-zone Bicep templates produced by UC1
  may reference Key Vault on the customer side — that is out of scope here.

Federated credentials and the service-principal-to-MCP mapping are owned by
the MCP infrastructure (not this repo). This repo only declares the
*intent* via `AGENTS.md` and `.github/copilot/mcp.json`.

## Alternatives Considered

- **GitHub PATs / Azure DevOps PATs** — easy day-1 but long-lived, leakable,
  and undermine zero-trust posture. Rejected.
- **Single service principal for all MCP calls** — operationally simple but
  collapses audit trails and gives every agent the union of permissions.
  Rejected.
- **Managed Identity on a hosted agent runtime** — would require a hosted
  service, contradicting [ADR-0002](0002-runtime-is-github-copilot-coding-agent.md).
  Rejected.

## Consequences

- **Positive**:
  - No long-lived secrets in the repo or in CI.
  - Per-agent service principals give least-privilege boundaries.
  - OBO preserves human attribution in the customer's audit logs.
- **Negative**:
  - Initial setup requires Entra admin access to register service
    principals and federated credentials on the MCP side.
  - OBO requires the MCP server to be configured as a confidential client
    in the target tenant.
- **Risks / follow-ups**:
  - Federated-credential subject claims must be reviewed for every new
    workflow added to `.github/workflows/`. The CODEOWNERS guard on
    `.github/workflows/` enforces review.
  - This ADR moves to **Accepted** in Sprint 3 when the first end-to-end
    UC1 deploy fires through WIF.

## References

- [ADR-0002 Runtime is GitHub Copilot coding agent](0002-runtime-is-github-copilot-coding-agent.md)
- [docs/SECURITY.md](../SECURITY.md)
- [sprints/sprint-03-uc1-end-to-end.md](../../sprints/sprint-03-uc1-end-to-end.md)
- [Workload Identity Federation overview](https://learn.microsoft.com/azure/active-directory/workload-identities/workload-identity-federation)
