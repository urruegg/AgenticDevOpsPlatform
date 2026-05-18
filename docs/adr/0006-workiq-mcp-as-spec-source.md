# 0006. WorkIQ MCP as the UC1 spec source

- **Status**: Accepted
- **Date**: 2026-05-25
- **Deciders**: @urruegg
- **Tags**: `uc1`, `mcp`, `spec`, `workiq`

## Context

UC1 (Build Subscription) needs a single, authoritative source for
landing-zone specifications. Per
[SPRINT_PLAN.md §9 Q2](../../sprints/SPRINT_PLAN.md#9-open-questions--resolutions),
SAs already author specs in **WorkIQ** (SharePoint/OneDrive-backed) and
the platform team does not want to maintain a parallel Git-stored spec
format. Constraints:

- Specs are authored in WorkIQ today; introducing a parallel JSON/YAML
  store in Git would create drift between "what SAs author" and "what
  the agent consumes".
- Per
  [ADR-0002](0002-runtime-is-github-copilot-coding-agent.md), there is
  no platform Python service that could centralise a custom WorkIQ SDK.
  The integration must be expressible as an MCP server entry.
- The Copilot coding agent must call the spec source under a clear
  identity (Workload Identity Federation for autonomous runs per
  [ADR-0004](0004-oidc-federation.md), OBO when human-triggered).
- The Spec Parser Agent must be able to fall back to a checked-in
  reference fixture for golden-task replay
  ([`samples/landing-zone-spec.json`](../../samples/landing-zone-spec.json))
  without requiring live WorkIQ access in CI.

## Decision

The **WorkIQ MCP server** is the UC1 spec source. It is declared in
[`.github/copilot/mcp.json`](../../.github/copilot/mcp.json) with
side-effect ceiling `read` and is used only by the `spec-parser` agent.
The contract between WorkIQ MCP and the agent is the JSON Schema at
[`schemas/landing-zone-spec.schema.json`](../../schemas/landing-zone-spec.schema.json):
any response that fails validation is refused by the agent with code
`REFUSE: spec-validation-failed`
(see [`agents/spec-parser/AGENT.md` §6](../../agents/spec-parser/AGENT.md#6-refusal-rules)).

A checked-in sample at
[`samples/landing-zone-spec.json`](../../samples/landing-zone-spec.json)
serves as the reference happy-path fixture for the golden tasks; it must
remain byte-identical to the WorkIQ MCP response for the corresponding
spec id, and changes to either side require a PR that updates both.

## Alternatives Considered

1. **Git-stored YAML/JSON specs**. Simple but creates drift with WorkIQ
   where SAs already author. Rejected.
2. **Excel ingestion (.xlsx) as the primary source**. SAs sometimes
   author in Excel before transcribing to WorkIQ. Deferred to Sprint 3
   (`FR-UC1-003`) as a secondary path; not a replacement for WorkIQ MCP.
3. **Direct SharePoint Graph API**. Possible, but bypasses the MCP
   contract that
   [ADR-0002](0002-runtime-is-github-copilot-coding-agent.md) defines
   as the only integration surface for the platform. Rejected.

## Consequences

### Positive

- Single source of truth: SAs author in WorkIQ, agent reads via MCP.
- Schema-validated boundary: the agent cannot proceed on a malformed
  spec.
- Auditability: every spec read is a `workiq-mcp.get-spec` MCP call on
  the agent's run history.
- Reproducible tests: `samples/landing-zone-spec.json` makes the
  happy-path golden task deterministic without live WorkIQ access.

### Negative

- WorkIQ MCP availability becomes a UC1 dependency. Mitigation: the
  agent refuses gracefully on `workiq-mcp` unavailability and the
  customer can re-trigger.
- Schema migration requires a coordinated WorkIQ + repo PR. Mitigation:
  the schema lives in `schemas/` under CODEOWNERS review.

## Implementation Notes

- The agent's allowed tool list is `workiq-mcp.get-spec` only (the MCP
  server may expose more; the agent restricts itself).
- Spec content is **never** logged or echoed in PR descriptions; only
  the SHA-256 hash + metadata are persisted.
- See [`agents/spec-parser/golden-tasks.md`](../../agents/spec-parser/golden-tasks.md)
  for the happy-path, missing-tag, and invalid-CIDR fixtures.

## References

- [ADR-0002 Runtime is GitHub Copilot coding agent](0002-runtime-is-github-copilot-coding-agent.md)
- [ADR-0003 Bicep as the IaC language for UC1 output landing-zone templates](0003-bicep-as-iac.md)
- [ADR-0004 OIDC federation for MCP-side service principals](0004-oidc-federation.md)
- [`agents/spec-parser/AGENT.md`](../../agents/spec-parser/AGENT.md)
- [`schemas/landing-zone-spec.schema.json`](../../schemas/landing-zone-spec.schema.json)
- [`sprints/sprint-02-uc1-spec-parser-happy-path.md`](../../sprints/sprint-02-uc1-spec-parser-happy-path.md)
