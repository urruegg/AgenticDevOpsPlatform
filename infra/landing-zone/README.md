# UC1 landing-zone Bicep library

| Field | Value |
|-------|-------|
| **Version** | 1.0.0 |
| **Date** | 2026-05-25 |
| **Author** | Urs Rüegg |
| **Status** | Draft |
| **Previous Version** | — (initial release; Sprint 2 MVP per [sprint-02-uc1-spec-parser-happy-path.md §3.1](../../sprints/sprint-02-uc1-spec-parser-happy-path.md#3-scope)) |

> **What this is**: The Bicep template library that the **`spec-parser`** agent
> assembles into a customer landing-zone PR (UC1 *output*). Per
> [ADR-0003 (Bicep as IaC)](../../docs/adr/0003-bicep-as-iac.md), all UC1 output
> templates are emitted as Bicep.
>
> **What this is not**: Infrastructure that hosts the platform itself. Per
> [ADR-0002](../../docs/adr/0002-runtime-is-github-copilot-coding-agent.md) the
> platform has **no hosted runtime**. The agent reads these files, copies and
> parametrises them into the customer's ADO Repos, and triggers a deployment
> via the `azure-devops-mcp` pipeline-run tool.

## Layout

| Path | Purpose |
|------|---------|
| `main.bicep` | Composition root (resource-group scope). |
| `modules/network.bicep` | VNet + subnets. |
| `parameters/<env>.bicepparam` | Sample parameter files. The agent emits these byte-identical for the same spec input (FR-UC1-005). |
| `pipelines/deploy.yml` | Sample ADO pipeline that validates + deploys the templates. |

## How the spec-parser uses this folder

1. Fetch the spec via `workiq-mcp` (read-only).
2. Validate against [`schemas/landing-zone-spec.schema.json`](../../schemas/landing-zone-spec.schema.json).
3. Render a `.bicepparam` file using the mapping table in
   [`agents/spec-parser/AGENT.md` §4](../../agents/spec-parser/AGENT.md#4-output-contract).
4. Copy `main.bicep` + `modules/` into the customer's ADO Repos branch via
   `azure-devops-mcp`.
5. Run `az bicep build` + `az deployment group what-if` (autonomous run via
   `azure-mcp`).
6. Post the what-if summary to the draft PR and wait for `approved-to-apply`.
7. On approval, trigger `pipelines/deploy.yml` against the customer's
   subscription via `azure-devops-mcp` `run-pipeline`.

## Validation

- `az bicep build --file infra/landing-zone/main.bicep` — CI runs this on
  every PR touching `infra/**` (see [.github/workflows/ci.yml](../../.github/workflows/ci.yml)).
- `az deployment group what-if` — out-of-band, against a staging subscription
  the customer owns. Not run by repo CI (no platform subscription).
