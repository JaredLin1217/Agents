# Agents Deployment

Use when copying this workflow into an explicitly authorized target repo.

## Fast Path

1. Confirm exact target path and write action.
2. Inspect target state before writing.
3. Detect the target layout from `AGENTS.md` and existing Agents dirs; preserve either root `docs/agents` or `.agents/docs`, not both.
4. Classify dirty target files as deploy scope, protected dirty, or target-owned legacy Agents docs.
5. Choose `core_bootstrap`, `full_workflow`, or `template_provider_mode`; default to `core_bootstrap` unless the user asks for more.
6. Build `deployed_file_set`, rewrite internal references for the selected layout, then copy/adapt only the `deployable_by_mode` groups listed by `mode_composition`.
7. Append/adapt `gitignore.fragment`; do not replace target `.gitignore` wholesale.
8. Validate only `deployed_file_set` for diff hygiene and source literals; report target legacy docs separately.

## Safety Gates

- The target path must already exist for dry-run inspection.
- A non-dry run may create a missing target directory only with `-CreateTarget` after exact path authorization.
- The script refuses provider self-writes, provider child-directory writes, absolute deploy paths, parent-directory escapes, blocklisted sources, and missing deploy sources.
- Deployment never repairs Windows permissions, ownership, ACLs, Git lock files, Git index state, or `.git` metadata. If the local repo is not writable, stop and use a writable clone or user-repaired workspace.
- The deployment report is part of `deployed_file_set`; validate that set instead of unrelated dirty target files.

## Provider Automation

From this provider repo, use the deployment script for repeatable target installs:

```powershell
.\scripts\deploy-agents-workflow.ps1 -TargetPath "D:\target\repo" -Mode core_bootstrap -DryRun
```

Remove `-DryRun` only after the target path and write action are explicitly authorized.
If the target directory does not exist and creation is explicitly intended, add `-CreateTarget` to the non-dry command.

For upgrades, use the same allowlisted operation and keep the target-owned state outside the deployed file set:

```powershell
.\scripts\deploy-agents-workflow.ps1 -TargetPath "D:\target\repo" -Mode core_bootstrap -Upgrade -DryRun
```

The script refuses to write back into the provider/source repo. For provider self-maintenance, use patches plus validation; use deployment dry-run only as a file-set compatibility check.

## Delegated Worker Use

When the controller receives a request like deploy this project to a target repo, assign at most one `deployment_worker` for the target path. The brief must include the exact target path, selected mode, dry-run/write scope, and the rule that writes stay inside `deployed_file_set`.

The worker runs dry-run first unless the assignment explicitly authorizes immediate write. The worker may inspect the target layout and deployed file set only; it must not edit target app code, copy provider runtime state, repair OS permissions, or modify `.git` metadata.

## Modes

Mode bullets are summaries only; exact groups, file sets, and target-layout rewrites come from `docs/agents/deploy.yaml`.

- `core_bootstrap`: `AGENTS.md`, Agents governance rules, project skill, gitignore fragment, deployment and closeout runbooks.
- `full_workflow`: `core_bootstrap` plus memory starters, runtime/evidence templates, and remaining runbooks.
- `template_provider_mode`: `full_workflow` plus recursive `docs/templates/agents/**` so the target can redeploy this workflow.

Hard fail on missing exact authorization, blocklisted copy, uninspected target-specific claim, or provider state in deployable templates.

Keep target state target-owned. Do not copy source status, employee history, memory entries, commits, remotes, tags, or runtime files.

PowerShell note: with `rg`, put options before `--`, then pattern and paths, for example `rg -n --fixed-strings --glob '!legacy/**' -- <pattern> <paths>`.

Runbook references use provider canonical paths; deployed target paths are layout-adjusted by `docs/agents/deploy.yaml`.
