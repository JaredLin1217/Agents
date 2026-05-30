# Agents Deployment

Use when copying this workflow into an explicitly authorized target repo.

## Fast Path

1. Confirm exact target path and write action.
2. Inspect target state before writing.
3. Detect the target layout from `AGENTS.md` and existing Agents dirs; preserve either root `docs/agents` or `.agents/docs`, not both.
4. Classify dirty target files as deploy scope, protected dirty, or target-owned legacy Agents docs.
5. Choose `core_bootstrap`, `full_workflow`, or `template_provider_mode`; default to `core_bootstrap` unless the user asks for more.
6. Build `deployed_file_set`, then copy/adapt only the `deployable_by_mode` groups listed by `mode_composition`.
7. Append/adapt `gitignore.fragment`; do not replace target `.gitignore` wholesale.
8. Validate only `deployed_file_set` for diff hygiene and source literals; report target legacy docs separately.

## Modes

- `core_bootstrap`: `AGENTS.md`, policy pack, project skill, gitignore fragment, deployment and closeout runbooks.
- `full_workflow`: `core_bootstrap` plus memory starters, runtime/evidence templates, and remaining runbooks.
- `template_provider_mode`: `full_workflow` plus recursive `docs/templates/agents/**` so the target can redeploy this workflow.

Hard fail on missing exact authorization, blocklisted copy, uninspected target-specific claim, or provider state in deployable templates.

Keep target state target-owned. Do not copy source status, employee history, memory entries, commits, remotes, tags, or runtime files.

PowerShell note: with `rg`, put options before `--`, then pattern and paths, for example `rg -n --fixed-strings --glob '!legacy/**' -- <pattern> <paths>`.

References: `docs/agents/deploy.yaml`, `docs/agents/verify.yaml`.
