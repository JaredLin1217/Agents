# Scripts
This directory owns repo-local executable checks and maintenance entry points.
Current command:
```powershell
.\scripts\validate.ps1
```
Public update document command:
```powershell
.\scripts\update-github-updates.ps1
```
Release-audit command:
```powershell
.\scripts\validate.ps1 -Full
```
Release-package export command:
```powershell
.\scripts\export-release-package.ps1
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
The public update entry point writes `docs/github-updates.md` from recent git
history. It is used by `.github/workflows/public-updates.yml` after branch
pushes and escapes non-ASCII commit text as ASCII codepoint markers so durable
documentation remains compatible with the English-only gate.
The GitHub Actions commit helper stages only `docs/github-updates.md`, commits
when that generated document changed, and pushes the update back to the same
branch.
The `-Full` mode adds release-audit gates for diff hygiene, deployment
safety/self-test, template/schema/skill/CI integrity, P0-P5 evidence, and size
budgets.
The release-package exporter writes a versioned package outside the repo and
creates `release-manifest.json` with the workflow version, source commit,
included file list, file hashes, and package hash. It excludes `.git`,
`.agents/runtime`, local Codex configuration, local environment configuration,
status records, evidence records, approval scratch files, and runtime validation
records.
Schema files define compact repo-local contracts. The validator enforces the
required top-level keys, nested paths, required values, and fixture cases needed
by the V2 policy pack without external package dependencies.
The deployment entry point reads `docs/agents/deploy.yaml`, detects the target
layout, builds a deployed file set, rewrites target paths when the target uses
`.agents/docs`, appends the gitignore fragment, and keeps runtime/local source
state out of the target. Use `-DryRun` before writing to an authorized target.