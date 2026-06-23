# V2 Structure Roadmap
## Status
Historical snapshot. Superseded by the current P0-P5 readiness ladder in
`docs/agents/version.yaml` and the executable gates in `scripts/validate.ps1`.
## Decision
The repo keeps a deployable, repo-local AI Agents workflow with:
- `AGENTS.md` as the root router.
- `.agents/skills/` for project-local skills.
- `docs/agents/*.yaml` as canonical governance.
- `docs/templates/agents/` as source-neutral deployable templates.
- `scripts/`, `schemas/`, `tests/`, `artifacts/`, and
  `.github/workflows/` as explicit v2 execution boundaries.
## Current Rule
Future changes must preserve exact-pair template drift checks, ignored runtime
boundaries, deployed file set ownership, source neutrality, and size gates.
