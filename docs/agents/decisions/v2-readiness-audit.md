# V2 Initial Readiness Audit

## Status

Verified readiness evidence for the v2 initial build.

## Scope

This audit checks whether the source repo has a usable v2 initial structure for
the Agents policy pack. It does not claim runtime multi-agent behavior, hard
isolation, target deployment, release readiness, or a clean committed state.

## Requirements

| Requirement | Evidence | Result |
|---|---|---|
| Project structure is explicit | `docs/project-structure.md` defines read order, role matrix, deploy policy, and v2 structure rule. | Pass |
| New v2 directory boundaries exist | `schemas/`, `scripts/`, `tests/`, `mcp/`, `artifacts/`, and `.github/workflows/` have tracked README or workflow files. | Pass |
| Local validation entry point exists | `scripts/validate.ps1` runs YAML, workflow YAML, required-file, schema-contract, fixture, placeholder, English-only, and runtime-boundary checks. | Pass |
| Canonical YAML has machine-readable contracts | `schemas/agents-*.schema.json` define required top-level keys and schema version constants for the five canonical YAML files. | Pass |
| Validator has regression fixtures | `tests/agents-policy-fixtures/schema-contracts/` includes one passing and two failing schema-contract cases. | Pass |
| CI checkpoint exists | `.github/workflows/checkpoint.yml` runs `scripts/validate.ps1` and `git diff --check` on pull requests and pushes to `main` or `master`. | Pass |
| Deployment boundaries remain conservative | `docs/agents/deploy.yaml` keeps new v2 support directories provider-source-only unless a deployment mode includes them. | Pass |
| Runtime/local state remains excluded | `scripts/validate.ps1` checks ignored runtime/local paths and tracked runtime paths. | Pass |
| Durable docs remain English-only | `scripts/validate.ps1` scans durable text roots for CJK characters. | Pass |
| Placeholder artifacts are rejected | `scripts/validate.ps1` scans durable text roots for placeholder markers and citation residue. | Pass |

## Current Limits

- The schema gate intentionally validates only top-level required keys and
  schema version constants.
- The workflow gate is lightweight YAML syntax checking, not GitHub Actions
  semantic linting.
- The MCP and artifact directories define boundaries only; they do not enable
  MCP servers or store promoted artifacts.
- Release and deployment audits remain out of scope until a target deployment
  or release task is requested.

## Verification

Current local checkpoint:

- `scripts/validate.ps1`: Pass
- `git diff --check`: Pass
- `git status -sb`: expected source changes plus pre-existing local
  `.codex/config.toml` modification

## Readiness Judgment

The source repo now has enough executable structure for a v2 initial static
policy-pack checkpoint.
