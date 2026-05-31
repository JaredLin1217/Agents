# Scripts

This directory owns repo-local executable checks and maintenance entry points.

Current command:

```powershell
.\scripts\validate.ps1
```

Release-audit command:

```powershell
.\scripts\validate.ps1 -Full
```

Deployment dry-run command:

```powershell
.\scripts\deploy-agents-workflow.ps1 -TargetPath "D:\target\repo" -Mode core_bootstrap -DryRun
```

Upgrade an existing target with the same allowlisted file set:

```powershell
.\scripts\deploy-agents-workflow.ps1 -TargetPath "D:\target\repo" -Mode core_bootstrap -Upgrade -DryRun
```

Remove `-DryRun` only for an explicitly authorized external target write. The script refuses to write into the provider/source repo, and it does not repair Windows permissions, ACLs, ownership, or `.git` metadata.

Deployment write command:

```powershell
.\scripts\deploy-agents-workflow.ps1 -TargetPath "D:\target\repo" -Mode core_bootstrap
```

The validation entry point stays small and composable. It uses no external
package dependencies and runs focused checks for lightweight YAML syntax,
workflow YAML syntax, required file references, schema contracts, validation
fixtures, placeholder scans, durable English-only rules, and
runtime/source-state boundaries.

The `-Full` mode adds release-audit gates for diff hygiene, exact-pair drift,
deploy manifest integrity, template bundle coverage, project skill metadata,
and size budgets.

Full JSON Schema validation belongs in `schemas/` and can be added later
without changing the command entry point.

The deployment entry point reads `docs/agents/deploy.yaml`, detects the target
layout, builds a deployed file set, rewrites target paths when the target uses
`.agents/docs`, appends the gitignore fragment, and keeps runtime/local source
state out of the target. Use `-DryRun` before writing to an authorized target.
