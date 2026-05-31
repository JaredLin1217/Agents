# V2 Checkpoint Package

## Status

Prepared as the next-stage package after the v2 initial readiness audit.

## Purpose

This package turns the v2 initial AI Agents workflow structure into a reviewable
checkpoint. It is not a release, deployment, tag, push, or runtime behavior
claim.

## Included Source Changes

| Area | Included paths | Purpose |
|---|---|---|
| Structure | `docs/project-structure.md`, `docs/templates/agents/project-structure.md` | Document the source repo ownership model and deploy boundaries. |
| Decisions | `docs/agents/decisions/v2-structure-roadmap.md`, `docs/agents/decisions/v2-readiness-audit.md`, this file | Record the roadmap, evidence, and package boundary. |
| Validation | `scripts/validate.ps1`, `scripts/README.md` | Provide the local executable checkpoint. |
| Contracts | `schemas/` | Define initial machine-readable contracts for canonical YAML files. |
| Fixtures | `tests/agents-governance-fixtures/` | Prove passing and failing schema-contract cases. |
| CI | `.github/workflows/checkpoint.yml`, `.github/workflows/README.md` | Run the fast checkpoint gate in GitHub Actions; full audit and whitespace checks remain local release-audit gates. |
| Boundaries | `mcp/README.md`, `artifacts/README.md`, `tests/README.md`, `schemas/README.md` | Reserve explicit source-controlled boundaries for later v2 work. |

## Excluded From This Package

- `.codex/config.toml`, because it is local Codex app state.
- Runtime ledgers, temp status files, generated artifacts, caches, build output,
  and deployment target state.
- Any target deployment result, release tag, branch push, or hard-isolation
  enforcement evidence.

## Acceptance Gates

Before committing or tagging this package, run:

```powershell
.\scripts\validate.ps1
git diff --check
git status -sb
```

Expected result:

- Validation passes.
- `git diff --check` has no output.
- Worktree status contains only intended source changes plus any explicitly
  excluded local Codex state.

## Release Decision

This package is ready for a normal git checkpoint after review. A deployment or
release should be handled as a separate task using `docs/agents/deploy.yaml`
and the `release_deploy_push_audit` profile.
