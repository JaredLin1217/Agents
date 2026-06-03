# Jared's AI Team
[![Checkpoint](https://github.com/JaredLin1217/Agents/actions/workflows/checkpoint.yml/badge.svg)](https://github.com/JaredLin1217/Agents/actions/workflows/checkpoint.yml)
[![Public Updates](https://github.com/JaredLin1217/Agents/actions/workflows/public-updates.yml/badge.svg)](https://github.com/JaredLin1217/Agents/actions/workflows/public-updates.yml)
Repo-local Agents workflow governance for Codex projects.
Jared's AI Team turns a repository into a self-describing AI work system. It
defines how an AI coding session should route work, assign tasks, verify claims,
deploy workflow files, export clean release packages, and keep local runtime
state out of source control.
The project is not an application framework or hosted service. Its primary
interface is the repository content: `AGENTS.md`, canonical YAML policies,
project-local skills, validation scripts, deployment scripts, schemas, and
runbooks that can be installed into another repository.
## What It Does
- Gives Codex a repo-local operating model instead of relying on hidden session
  habits, global memory, or private machine settings.
- Keeps routine context small by loading `docs/agents/ai-runtime.yaml` first and
  expanding only the named files required for the current route.
- Separates deployable workflow content from `.git`, `.codex`, runtime state,
  secrets, local evidence, and target-owned project files.
- Supports simple single-agent edits, multi-agent workflows, and an optional
  enterprise dispatch layer where the controller assigns work to department
  leaders instead of individual workers.
- Adds a supervised workflow artifact layer for local packets, approval gates,
  verification results, collection reports, and final workflow evidence.
- Adds a context compact layer for safe resume, handoff, auto-compaction, and
  employee closeout summaries without storing raw transcript.
- Provides repeatable validation gates for edits, policy changes, commits,
  deployments, release exports, and enterprise dispatch records.
- Packages the workflow as a source-neutral template bundle that can be copied
  into authorized target repositories.

## Why It Saves Tokens And Context
Jared's AI Team is designed as an LLM-readable operating layer, not a long-form
manual. It reduces token use by making the model read less, infer less, and
repeat less.
- Route-first loading keeps each task scoped to the smallest canonical file set
  needed for that route.
- Canonical YAML uses stable keys and compact structures so the model can parse
  policy by shape instead of re-reading long prose.
- Template mirrors preserve deployability without duplicating divergent rules in
  multiple places.
- Validation scripts turn correctness checks into command output, reducing
  repeated manual reasoning about repository state.
- Department-level dispatch lets the controller integrate leader reports instead
  of every raw worker message.
- Runtime artifacts keep temporary packets, status, and evidence out of durable
  documentation and release packages.
- Context compact summaries preserve the latest request, route, changed files,
  verification state, risks, employees, and next step without preserving raw
  transcript.
- Verified employee closeout reduces stale sidebar or history residue that would
  otherwise pollute later context.

## Core Features
| Feature | How It Helps |
|---|---|
| Route-minimal runtime | `docs/agents/ai-runtime.yaml` maps each request to the smallest canonical file set needed for the task. |
| Project-local operating rules | `AGENTS.md` and `.agents/skills/project-isolation-workflow/` define portable behavior inside the repo. |
| Enterprise dispatch | `docs/agents/org.yaml`, `model-policy.yaml`, and `dispatch.yaml` define department leaders, allowed worker roles, reports, and escalations. |
| Workflow artifacts | `docs/agents/workflow-artifacts.yaml` defines local workflow instances, packets, results, approval gates, collection reports, and artifact-backed dispatch simulations. |
| Context compact contract | `docs/agents/context-compact.yaml` defines safe resume and handoff summaries that keep the latest request, verification state, risks, and employee closeout counts without raw transcript. |
| Tier-first model policy | Work is assigned to capability tiers such as `low_fast`, `quick_code`, `code_standard`, `senior_review`, and `principal` instead of being hard-bound to one model ID. |
| Multi-agent lifecycle | `docs/agents/workflows.yaml` defines assignment ownership, ledger behavior, roster fallback, closeout, scoring, and recovery. |
| Validation profiles | `docs/agents/verify.yaml` selects focused checks for scoped edits, policy edits, deployment, release, and enterprise dispatch. |
| Deployment provider mode | `scripts/deploy-agents-workflow.ps1` installs the workflow into allowlisted target repositories without copying local runtime state. |
| Release package export | `scripts/export-release-package.ps1` creates a clean package manifest with version, commit, file list, file hashes, and package hash. |
| Public update automation | `.github/workflows/public-updates.yml` refreshes `docs/github-updates.md` after branch pushes. |
## Common Usage
### 1. Validate The Current Repository
Run the default validation gate before making source-state claims:
```powershell
.\scripts\validate.ps1
```
Run the broader audit before deployment or release work:
```powershell
.\scripts\validate.ps1 -Full
```
### 2. Use The Workflow In A Codex Session
Start from the repo-local instructions:
1. Read `AGENTS.md`.
2. Read `docs/agents/ai-runtime.yaml`.
3. Expand only the canonical files named by the selected route.
4. Verify with the matching profile in `docs/agents/verify.yaml`.
5. Close out with the required isolation report.
Useful request styles:
```text
Make a scoped documentation edit and verify it with the smallest profile.
```
```text
Dispatch this task through the QA department leader and return one department report.
```
```text
Deploy this Agents workflow to D:\target\repo with a dry run first, then verify.
```
### 3. Run An Artifact-Backed Workflow
Create, simulate, verify, and collect a local workflow artifact without adding it
to source control:
```powershell
.\scripts\agents-workflow.ps1 -Action New -WorkflowId "example"
.\scripts\agents-workflow.ps1 -Action SimulateDispatch -WorkflowId "example" -Level 2
.\scripts\agents-workflow.ps1 -Action Verify -WorkflowId "example"
.\scripts\agents-workflow.ps1 -Action Collect -WorkflowId "example"
```
Live artifacts are local runtime state under `.agents/runtime/workflows/`.
`.workflow/` is accepted only as an import compatibility alias. Neither location
is deployable or releasable.
### 4. Deploy Into Another Repository
Always dry-run first against an exact authorized target path:
```powershell
.\scripts\deploy-agents-workflow.ps1 -TargetPath "D:\target\repo" -Mode core_bootstrap -DryRun
```
Upgrade an existing target after reviewing the dry-run plan:
```powershell
.\scripts\deploy-agents-workflow.ps1 -TargetPath "D:\target\repo" -Mode core_bootstrap -Upgrade
```
Deployment modes:
| Mode | Includes |
|---|---|
| `core_bootstrap` | Root rules, canonical Agents YAML, project skill, gitignore fragment, and core runbooks. |
| `full_workflow` | Core bootstrap plus assignment, status, evidence, feedback, memory starter, and maintenance templates. |
| `template_provider_mode` | Full workflow plus the recursive template bundle so the target can redeploy the workflow. |
Deployment is allowlist-based and preserves target app code, `.git`, `.codex`,
runtime files, secrets, target-owned memory, and local environment state unless a
narrower targeted action is explicitly authorized.
### 5. Export A Clean Release Package
```powershell
.\scripts\export-release-package.ps1
```
The release package excludes `.git/`, `.agents/runtime/`,
`.agents/runtime/workflows/`, `.workflow/`, local Codex configuration, local
environment configuration, local status records, and other machine-owned state.
The generated manifest records workflow version, source commit, included files,
file hashes, and package hash.
## Enterprise Dispatch
Version `2.1.0` added the Enterprise Dispatch Layer. Version `2.2.0` can back
that dispatch with local workflow artifacts for packeted assignments,
verification, approval gates, collection, and final reports.
Version `2.2.1` adds context compact rules for resume, handoff, and employee
closeout continuity.
Default departments:
- Executive Office
- PMO
- Architecture
- Engineering
- DevOps
- QA
- Security
- Documentation
- Provider Management
Operating model:
- The controller assigns work to department leaders.
- Department leaders may split work internally to allowed worker roles.
- Workers report to their leader, not directly to the controller.
- Leaders return one department report with verification, risks, escalations,
  and isolation details.
- Invalid routing, authority violations, failed verification, or unsuitable model
  tiers must produce an escalation record.
The canonical files are:
- `docs/agents/org.yaml`
- `docs/agents/model-policy.yaml`
- `docs/agents/dispatch.yaml`
- `docs/agents/workflow-artifacts.yaml`
- `docs/agents/context-compact.yaml`
- `docs/agents/workflows.yaml`
- `docs/agents/schemas.yaml`
- `docs/agents/verify.yaml`
## Validation Model
Validation is selected by claim scope:
| Scope | Expected Gate |
|---|---|
| Answer-only with no current-state claim | No command required. |
| Current state claim | Named state check from `docs/agents/verify.yaml`. |
| Scoped edit | Fast status, diff, and focused validation. |
| Policy or template edit | Mirror-pair, schema, and durable-rule checks. |
| Commit, tag, or push checkpoint | Staged hygiene, placeholder, runtime, and local-state checks. |
| Deployment or release | Deployment self-test, template integrity, schema coverage, package exclusions, and handoff checks. |
| Enterprise dispatch | Department leader references, model tier references, report routing, and escalation records. |
| Workflow artifacts | Local workflow state, packet ownership, approval gates, route guardrails, collection reports, and runtime blocklists. |
| Context compact | Required summary fields, raw transcript exclusion, subagent closeout counts, and runtime compact event boundary. |
The source of truth for these gates is `docs/agents/verify.yaml`.
## Repository Map
| Path | Purpose |
|---|---|
| `AGENTS.md` | Entry-point operating rules for Codex sessions. |
| `docs/agents/*.yaml` | Canonical route, workflow, policy, deployment, verification, schema, MCP, dispatch, model, context compact, and version rules. |
| `.agents/skills/project-isolation-workflow/` | Project-local Codex skill for isolation, deployment, memory, maintenance, and multi-agent work. |
| `docs/templates/agents/` | Source-neutral deployable template bundle. |
| `docs/runbooks/` | Operational procedures for deployment, closeout, audits, skills, sessions, and maintenance. |
| `scripts/validate.ps1` | Main local and CI validation entry point. |
| `scripts/agents-workflow.ps1` | Local workflow artifact helper for new, verify, collect, simulate, and normalize actions. |
| `scripts/deploy-agents-workflow.ps1` | Allowlisted deployment entry point for target repositories. |
| `scripts/export-release-package.ps1` | Clean release package exporter. |
| `scripts/update-github-updates.ps1` | Public GitHub update log generator. |
| `schemas/` | JSON Schema contracts used by validation. |
| `.github/workflows/` | GitHub Actions checkpoint and public update automation. |
For a detailed file-role matrix, see `docs/project-structure.md`.
## Current Workflow Version
Current Agents workflow version: `2.2.1` (`v2`).
The canonical source is `docs/agents/version.yaml`. Deployment extracts version
metadata from that file, copies the matching version file into the target
deployed file set, and records the aligned version in the deployment report.
## Documentation
- `docs/runbooks/agents-deployment.md`
- `docs/runbooks/multi-agent-workflow.md`
- `docs/runbooks/repository-maintenance.md`
- `docs/runbooks/task-closeout.md`
- `docs/github-updates.md`
- `scripts/README.md`
- `schemas/README.md`
- `mcp/README.md`
## Project Boundaries
- Global Memory is not used unless the user explicitly requests it.
- Global/system skills are not used by default.
- Project-local skills under `.agents/skills/` are part of this repository.
- `.agents/runtime/`, `.agents/runtime/workflows/`,
  `.agents/runtime/compact-events.jsonl`, `.workflow/`, `.codex/`, status
  records, evidence records, secrets, and local environment state are not
  deployable workflow content.
- Deployment reports target-owned legacy Agents files separately instead of
  treating a dirty target repository as a failed deployment.
## Contributing
See `CONTRIBUTING.md` for local workflow rules, validation expectations, and
content that should not be committed.
See `CODE_OF_CONDUCT.md` for participation expectations.
## Security
See `SECURITY.md` for reporting guidance. Do not publish secrets, local Codex
configuration, target credentials, private deployment evidence, or machine-local
runtime data in issues.
## License
Copyright 2026 Yu-Jie, Lin.
Licensed under the Apache License, Version 2.0. See `LICENSE` for the full
license text and `NOTICE` for the project notice and additional disclaimer.
Unless required by applicable law or agreed to in writing, this repository is
provided on an "AS IS" basis, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
either express or implied.
