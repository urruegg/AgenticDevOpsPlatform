# 0003. Bicep as the IaC language for UC1 output landing-zone templates

- **Status**: Proposed
- **Date**: 2026-05-18
- **Deciders**: @urruegg
- **Tags**: `infra`, `iac`, `uc1`

## Context

UC1 (Build Subscription) produces Infrastructure-as-Code that lands a customer
Azure subscription. Per
[ADR-0002 Runtime is GitHub Copilot coding agent](0002-runtime-is-github-copilot-coding-agent.md),
this platform itself has no hosted runtime and no platform-runtime Azure
infrastructure — but the UC1 agent **does** assemble Bicep modules for the
customer's landing zone and commits them to ADO Repos. The question is which
IaC dialect those *output* templates use.

Constraints:

- Templates are read and reviewed by the customer's platform team — must be
  first-class Azure citizens with the lowest learning curve for an Azure
  audience.
- Templates are validated in CI via `az bicep build` and
  `az deployment group what-if` before any `approved-to-apply` step
  ([AGENTS.md §4](../../AGENTS.md#4-confirmation-rule-for-deploy--delete)).
- The `azure-mcp` server has first-class Bicep support (build, validate,
  what-if). Terraform support is shallower and would require an additional
  toolchain on the runner.
- Azure Verified Modules (AVM) publish Bicep modules with security and
  policy defaults already baked in.

## Decision

UC1 emits all landing-zone templates as **Bicep**. The Spec Parser agent
composes modules from `infra/modules/` into `infra/main.bicep` and parameter
files under `infra/<env>/`. CI runs `az bicep build` on every PR that
modifies `infra/**` and `az deployment group what-if` against a staging
deployment scope before approval.

Terraform may be considered only when (a) a customer explicitly mandates it
in the spec, or (b) a multi-cloud requirement enters scope — both
out-of-scope for the current roadmap. A future ADR would record any such
exception.

## Alternatives Considered

- **Terraform** — Broader ecosystem and multi-cloud. Cons: additional
  toolchain on the agent runtime, shallower MCP support, customer reviewers
  in Azure-only orgs find Bicep more familiar, and the platform has no
  multi-cloud requirement.
- **ARM JSON templates** — Direct Azure support but verbose; harder for
  agents to assemble compositionally; effectively superseded by Bicep.
- **Pulumi / CDKTF** — Programmatic IaC. Adds a general-purpose runtime
  inside the customer landing-zone repo, which contradicts the
  Markdown-and-YAML-only stance of this platform.

## Consequences

- **Positive**:
  - First-class Azure tooling, AVM module reuse, lightweight CI.
  - `azure-mcp` `what-if` flow maps cleanly onto Bicep deployments.
  - Customer reviewers familiar with Azure can read and approve PRs without
    extra training.
- **Negative**:
  - Locks UC1 outputs to Azure. Acceptable today; revisit if multi-cloud
    becomes a requirement.
- **Risks / follow-ups**:
  - Bicep `what-if` occasionally reports false positives on data-plane
    fields; mitigated by selective `--exclude-change-types` and reviewer
    judgement.
  - This ADR moves to **Accepted** in Sprint 2 when the first UC1 output
    module is merged.

## References

- [ADR-0002 Runtime is GitHub Copilot coding agent](0002-runtime-is-github-copilot-coding-agent.md)
- [sprints/sprint-02-uc1-spec-parser-happy-path.md](../../sprints/sprint-02-uc1-spec-parser-happy-path.md)
- [docs/INFRASTRUCTURE.md](../INFRASTRUCTURE.md)
- [Azure Verified Modules](https://aka.ms/avm)
