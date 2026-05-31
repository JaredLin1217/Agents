# Agents Templates

Source-neutral starter bundle for authorized target repos.

## What This Is

Deployable, source-neutral Agents rules for target repos.

## How To Deploy

Use `docs/agents/deploy.yaml` and choose one mode:

- `core_bootstrap`: default; router, Agents governance rules, project skill, gitignore fragment, deployment and closeout runbooks.
- `full_workflow`: core plus memory starters, runtime/evidence templates, and remaining runbooks.
- `template_provider_mode`: full workflow plus recursive `docs/templates/agents/**`.

For upgrades, run the same selected mode with dry-run first and update only the deployed file set. Preserve target runtime state, local Codex config, memory entries, status files, commits, remotes, and deployment history.

## What Not To Copy

Do not copy provider status, employee history, memory entries, commits, remotes, tags, runtime files, or filled evidence. Exact target authorization and target inspection are required before writing.
