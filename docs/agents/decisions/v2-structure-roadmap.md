# V2 Structure Roadmap

## Status

Implemented for the v2 initial AI Agents workflow checkpoint.

## Context

The repo currently works as a project-isolated AI Agents workflow kit. It
already contains the root router, canonical YAML governance files,
project-local skill, runbooks, templates, memory docs, and decision records.
It does not claim live multi-agent runtime behavior, but it needs the tracked
validation, schema, test, MCP registry, CI, and artifact boundaries required
for a fully governed v2 workflow.

The v2 structure should be introduced without disrupting existing deploy
template mirror pairs or local runtime boundaries.

## Decision

Introduce v2 structure in stages:

1. Create tracked directory boundaries for schemas, scripts, tests, MCP,
   artifacts, and GitHub workflow definitions.
2. Document the target ownership model in `docs/project-structure.md`.
3. Add `scripts/validate.ps1` as the first executable checkpoint.
4. Add schemas and fixtures only after the validation entry point exists.
5. Add CI only after the same checks pass locally.
6. Move or rename existing runbooks/templates/decisions only in a dedicated
   follow-up change that updates exact-pair drift checks and deployment rules.

## Target Ownership

| Path | Owner | Stage |
|---|---|---|
| `AGENTS.md` | Root router | Existing |
| `.agents/skills/` | Project-local skills | Existing |
| `.agents/runtime/` | Ignored runtime coordination | Existing local-only |
| `docs/agents/*.yaml` | Canonical Agents governance rules | Existing |
| `docs/runbooks/` | Human task entry points | Existing |
| `docs/templates/agents/` | Deployable template bundle | Existing |
| `docs/memory/` | Provider-local memory docs | Existing |
| `docs/decisions/` | Provider-local decision records | Existing |
| `docs/agents/decisions/` | V2 structure and Agents workflow decisions | New |
| `schemas/` | Machine-readable policy contracts | New |
| `scripts/` | Local validation and maintenance commands | New |
| `tests/` | Fixtures and automated validation tests | New |
| `mcp/` | MCP capability registry and boundaries | New |
| `artifacts/` | Trace, eval, and audit artifact boundary | New |
| `.github/workflows/` | CI delivery lane | New |

## Implementation Result

The initial structure batch added:

- Tracked directory boundaries for schemas, scripts, tests, MCP, artifacts, and
  CI workflows.
- `scripts/validate.ps1` as the local Agents workflow checkpoint.
- Schema contracts for the canonical YAML files.
- Regression fixtures for schema-contract validation.
- A GitHub Actions checkpoint workflow that runs the same local validation.
- A readiness audit under `docs/agents/decisions/`.

## Follow-Up Work

Future changes should stay incremental:

- Promote the checkpoint package into a commit when the user requests a git
  checkpoint.
- Expand schemas beyond top-level required keys only when the policy fields are
  stable enough to validate semantically.
- Add MCP server definitions only after a real local MCP capability is selected.
- Move or rename existing runbooks/templates/decisions only in a dedicated
  change that updates exact-pair drift checks and deployment rules.

## Consequences

This keeps the current AI Agents workflow stable while making the v2 execution
surface explicit. It also avoids a large file move before validation and drift
checks exist.
