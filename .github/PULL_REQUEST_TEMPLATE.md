<!-- markdownlint-disable MD041 -->
## Summary

<!-- 1–3 sentences: what changed and why. -->

## Linked Issue / Work Item

<!-- e.g., Closes #123 or ADO Boards work item link -->

## Requirements Implemented

> **Required** by [NFR-GOV-006](../docs/PRD.md#56-governance--compliance-nfr-gov-).
> List every PRD requirement ID this PR advances. Use `partial:` if the
> requirement is not fully verified by this PR.

- FR-…: <one-line description>
- NFR-…: <one-line description>

## Sprint Context

- Sprint: `S<N>` — [link](../sprints/sprint-NN-name.md)
- User stories: `S<N>-<n>`, …

## Validation Evidence

<!-- Commands executed + outcomes. Paste tail of relevant output. -->
- [ ] `pytest -q`
- [ ] `ruff check .`
- [ ] `black --check .`
- [ ] `az bicep build` / `az deployment group what-if` (if infra changed)
- [ ] `pytest evals/ -q` (if prompts/tools/agents changed)

## Eval Impact

<!-- For prompts, tools, or agent control-flow changes only. -->
- Golden tasks affected: …
- Pass-rate before → after: …
- Sample run trace link (App Insights): …

## API Impact

<!-- New/changed endpoints, MCP tool contracts, CLI commands. State "none" if none. -->

## Infrastructure Impact

<!-- Bicep modules added/changed; `what-if` summary. State "none" if none. -->

## Security Impact

<!-- New identities, RBAC, secrets, network changes. State "none" if none. -->

## Data Impact

<!-- Cosmos DB containers, partition keys, retention, PII. State "none" if none. -->

## Documentation Updated

- [ ] `docs/PRD.md` (traceability matrix §7 updated if new requirement or scope change)
- [ ] `docs/<relevant>.md` (architecture, security, data, infra, AI, ALM)
- [ ] `sprints/sprint-NN-*.md` (acceptance criteria reflected)
- [ ] `docs/adr/*.md` (if a cross-cutting decision was made)
- [ ] Runbooks (`docs/runbooks/*.md`) if operational behavior changed

## Residual Risks / Open Questions

<!-- Anything reviewers should look at first. -->

---

### Reviewer Checklist (carried from [.github/copilot-instructions.md §7](../.github/copilot-instructions.md#7-code-review-checklist))

- [ ] CI checks pass (lint, test, build, security scan, IaC validate, eval)
- [ ] Coverage ≥ 80 % on changed files
- [ ] No hard-coded secrets, subscription IDs, tenant IDs, URLs, or resource names
- [ ] Commit messages follow Conventional Commits
- [ ] Requirements section above is complete and references valid PRD IDs
- [ ] Traceability matrix in `docs/PRD.md` §7 is consistent
