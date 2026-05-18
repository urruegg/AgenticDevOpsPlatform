# 0007. OBO vs Service Identity for MCP-side Calls

- **Status**: Proposed
- **Date**: 2026-05-25
- **Deciders**: Urs Rüegg (platform lead)
- **Tags**: `agents`, `security`, `identity`

## Context

UC1 (and to a lesser extent UC2 and UC3) requires the GitHub Copilot coding
agent to call MCP-exposed APIs (WorkIQ, Azure, Azure DevOps) on behalf of a
human approver who comments `approved-to-apply` on a draft PR. Two identity
patterns are available at the MCP boundary:

1. **On-Behalf-Of (OBO)** — the human approver's token is exchanged at the
   MCP server for a downstream token; the downstream API sees the human as
   the caller.
2. **Service identity (workload-identity federation)** — the MCP service
   principal is the caller; the human's identity appears only in audit
   metadata that the agent attaches to the request (e.g. a header, an
   ADO PR comment, a Git commit trailer).

Per [ADR-0002](0002-runtime-is-github-copilot-coding-agent.md), there is no
bespoke service to perform a token exchange. Token exchange (if any) happens
inside the MCP server, not inside this repository.

This ADR is a placeholder pending the Sprint 3 (UC1 end-to-end) decision.
See [sprints/sprint-03-uc1-end-to-end.md](../../sprints/sprint-03-uc1-end-to-end.md).

## Decision

To be finalised in Sprint 3 once each MCP server's supported auth modes are
verified end-to-end. The expected outcome is:

- **OBO** is preferred for **write** and **deploy** operations on customer
  resources so the audit trail attributes the action to the human approver.
- **Service identity** is acceptable for **read** operations and for
  workflows where the customer's MCP server does not implement OBO.
- The agent must record, in the resulting PR or comment, which identity
  pattern was used per MCP call.

## Alternatives Considered

- **OBO everywhere**: cleanest audit trail; blocked when an MCP server does
  not support token exchange.
- **Service identity everywhere**: simplest to operate; weaker audit trail
  for write/deploy actions.
- **Per-tool fallback rules** (chosen direction): OBO preferred; service
  identity as documented fallback with explicit attribution in PR/comment
  metadata.

## Consequences

- **Positive**: Audit trail stays accurate for high-impact actions.
- **Negative**: Per-MCP-server validation work in Sprint 3.
- **Risks / follow-ups**: Token scope mismatches must be caught early; see
  the Sprint 3 risk table.

## References

- [ADR-0002](0002-runtime-is-github-copilot-coding-agent.md)
- [Sprint 3 — UC1 End-to-End](../../sprints/sprint-03-uc1-end-to-end.md)
