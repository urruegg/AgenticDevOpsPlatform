# 0001. Record Architecture Decisions

- **Status**: Accepted
- **Date**: 2026-05-18
- **Deciders**: Platform team
- **Tags**: `process`, `documentation`

## Context
We need a lightweight, durable way to capture significant cross-cutting
decisions for the Agentic DevOps Platform — including agent design, identity
patterns, IaC choices, model selection, and security trade-offs — so future
contributors (human and agent) understand *why* the system is built the way
it is.

## Decision
Adopt **Architecture Decision Records (ADRs)** in `docs/adr/` following the
Michael Nygard format. Use a zero-padded sequence number per ADR, keep them
short (one page where possible), and maintain an index in
[`docs/adr/README.md`](README.md).

## Alternatives Considered
- **No ADRs** — relies on tribal knowledge; rejected.
- **Decision log in a single Markdown file** — does not scale; rejected.
- **RFC repo / separate tool** — overhead too high for current stage; rejected.

## Consequences
- **Positive**: explicit, versioned rationale alongside code; easy diff in PRs;
  Copilot agents can read past decisions before proposing changes.
- **Negative**: small additional overhead per cross-cutting change.
- **Risks / follow-ups**: enforce via PR template checklist that any
  cross-cutting change either references or creates an ADR.

## References
- Michael Nygard, *Documenting Architecture Decisions* (2011).
- [`docs/ARTEFACTS.md`](../ARTEFACTS.md) for the full doc catalogue.
