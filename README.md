# Jared's AI Team

[![Checkpoint](https://github.com/JaredLin1217/Agents/actions/workflows/checkpoint.yml/badge.svg)](https://github.com/JaredLin1217/Agents/actions/workflows/checkpoint.yml)
[![Public Updates](https://github.com/JaredLin1217/Agents/actions/workflows/public-updates.yml/badge.svg)](https://github.com/JaredLin1217/Agents/actions/workflows/public-updates.yml)

Repo-local AI workflow core runtime system for Codex projects.

Jared's AI Team turns a repository into a self-describing AI work system. It
defines how an AI coding session should route work, assign tasks, verify claims,
deploy workflow files, export clean release packages, and keep local runtime
state out of source control.

The project is not an application framework or hosted service. Its primary
interface is the repository content: `AGENTS.md`, canonical YAML policies,
project-local skills, validation scripts, deployment scripts, schemas, and
runbooks that can be installed into another repository.

## Current Version
Current Agents workflow version: `2.5.0` (`core-runtime`).

| Field | Value |
|---|---|
| Canonical version source | `docs/agents/version.yaml` |
| Public README source of truth | This section must match the canonical version metadata. |
| Deployment alignment | Deployment reads the canonical version metadata, copies the matching version file into the deployed file set, and records the aligned version in the deployment report. |
| Release alignment | Release export records the canonical version, source commit, included file list, file hashes, and package hash. |

## What It Does
- Gives Codex a repo-local operating model instead of relying on hidden session
  habits, global memory, or private machine settings.
- Keeps routine context small by loading `docs/agents/ai-runtime.yaml` first and
  expanding only the named files required for the current route.
- Separates deployable workflow content from `.git`, `.codex`, runtime state,
  secrets, local evidence, and target-owned project files.
- Supports simple single-agent edits, multi-agent workflows, and enterprise
  dispatch where the controller assigns work to department leaders instead of
  individual workers.
- Uses runtime execution evidence as the shared source for runs, steps,
  approvals, tool evidence, results, cleanup, and workflow artifacts.
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
- Collaborator windows allow named, recoverable Codex work sessions to stand in
  for department leaders without storing live thread ids in deployable files.
- Verified employee closeout reduces stale sidebar or history residue that would
  otherwise pollute later context.

## Core Modules
| Module | Added In | Main Files | What It Adds |
|---|---|---|---|
| Versioned public workflow | `2.0.0` | `docs/agents/version.yaml`, `README.md` | Canonical version metadata, README alignment, deployment version extraction, and public release identity. |
| Route-minimal runtime | Initial release, strengthened through `2.5.0` | `docs/agents/ai-runtime.yaml` | A small route table that tells Codex exactly which canonical files to load for each task. |
| Project-local operating rules | Initial release | `AGENTS.md`, `.agents/skills/project-isolation-workflow/` | Portable repo-local behavior for isolation, deployment, maintenance, multi-agent work, and closeout. |
| Enterprise dispatch | `2.1.0` | `docs/agents/org.yaml`, `docs/agents/model-policy.yaml`, `docs/agents/dispatch.yaml` | Controller-to-department-leader assignment, leader-owned internal delegation, department reports, escalation records, and tier-first model selection. |
| Workflow artifacts | `2.2.0` | `docs/agents/workflow-artifacts.yaml`, `scripts/agents-workflow.ps1` | Runtime-local workflow instances, packets, approval gates, collection reports, and artifact-backed dispatch simulations. |
| Context compact | `2.2.1` | `docs/agents/context-compact.yaml` | Safe resume and handoff summaries that preserve current task state without storing raw transcript. |
| Collaborator windows | `2.3.0` | `docs/agents/collaborators.yaml` | Named, recoverable Codex work sessions for department leaders, with create, rename, report, archive, and close evidence rules. |
| Core runtime contract | `2.5.0` | `docs/agents/core-system.yaml` | System boundary, canonical file set, runtime-local blocklists, and deploy or release contract. |
| Runtime execution evidence | `2.5.0` | `docs/agents/runtime-execution.yaml`, `scripts/agents-runtime.ps1` | Runs, steps, approvals, tool evidence, results, escalations, collection, verification, and cleanup proof. |
| Provider adapters | `2.5.0` | `docs/agents/provider-adapters.yaml` | Provider capability boundaries and replaceable model tier mapping without hard-binding workflows to one model id. |
| Route packs | `2.5.0` | `docs/agents/route-packs.yaml`, `scripts/export-route-pack.ps1` | Deterministic minimal read-pack manifests for cacheable, low-token route loading. |
| Knowledge footprint | `2.5.0` | `docs/agents/knowledge-footprint.yaml` | Compact cross-window recovery evidence with scope, opened files, evidence refs, gaps, conclusion, and resume pointer. |
| Validation profiles | Strengthened every release | `docs/agents/verify.yaml`, `scripts/validate.ps1` | Focused gates for edits, policy changes, deployment, release, enterprise dispatch, runtime execution, route packs, and public version alignment. |
| Deployment provider mode | `2.1.0`, strengthened through `2.5.0` | `scripts/deploy-agents-workflow.ps1`, `docs/agents/deploy.yaml` | Allowlisted installation into target repositories while preserving `.git`, `.codex`, runtime state, secrets, and target-owned files. |
| Release package export | `2.1.0`, strengthened through `2.5.0` | `scripts/export-release-package.ps1` | Clean package manifest with canonical version, source commit, file list, file hashes, package hash, and runtime blocklist checks. |
| Public update automation | `2.0.0` | `.github/workflows/public-updates.yml`, `docs/github-updates.md` | GitHub Actions update log generated from recent public branch history after pushes. |

## Version Feature History
| Version | Added Functions |
|---|---|
| `2.5.0` | Core Runtime System positioning; core system policy; runtime execution policy and helper; provider adapter policy; route pack policy and exporter; knowledge footprint policy; stronger runtime blocklists; legacy residue checks; release and deployment package audits. |
| `2.3.0` | Collaborator Window Dispatch Layer; named department-leader Codex sessions; create, rename, report, archive, and close lifecycle; worker-window blocking; runtime-local thread evidence exclusion. |
| `2.2.1` | Context Compact Layer; auto-compaction and handoff rules; resume pointer; retained facts, dropped details, risks, changed files, subagent closeout counts, and raw transcript exclusion. |
| `2.2.0` | Supervised Workflow Artifact Layer; local workflow state; department leader packets; worker packets; verification packets; escalation packets; approval gates; collect and normalize workflow reports. |
| `2.1.0` | Enterprise Dispatch Layer; organization definition; department leaders; allowed worker roles; tier-first model policy; leader-only controller integration; escalation records; clean release package export. |
| `2.0.0` | Public workflow version source; README version alignment; deployment-time version extraction; Apache-2.0 license and disclaimer; public issue and PR templates; GitHub update automation. |
| Initial release | Compact AI runtime route file; deployable template mirror; validation and deployment rules for the first repo-local Agents workflow package. |

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
### 3. Record Runtime Execution Evidence
Create, update, verify, collect, and clean a read-only runtime execution record
without adding it to source control:
```powershell
.\scripts\agents-runtime.ps1 -Action NewRun -RunId "example" -RuntimeRoot "$env:TEMP\codex-agent-status\jared-s-ai-team\runtime\example"
.\scripts\agents-runtime.ps1 -Action AddStep -RunId "example" -RuntimeRoot "$env:TEMP\codex-agent-status\jared-s-ai-team\runtime\example" -Step "read_only"
.\scripts\agents-runtime.ps1 -Action AddResult -RunId "example" -RuntimeRoot "$env:TEMP\codex-agent-status\jared-s-ai-team\runtime\example" -Result "completed" -Summary "read-only example completed"
.\scripts\agents-runtime.ps1 -Action Verify -RunId "example" -RuntimeRoot "$env:TEMP\codex-agent-status\jared-s-ai-team\runtime\example"
.\scripts\agents-runtime.ps1 -Action Cleanup -RunId "example" -RuntimeRoot "$env:TEMP\codex-agent-status\jared-s-ai-team\runtime\example"
```
Runtime evidence belongs under `.agents/runtime/**` or an approved temporary
status path. It is not deployable or releasable.
### 4. Export A Route Pack
Generate a deterministic minimal read pack for one route:
```powershell
.\scripts\export-route-pack.ps1 -RouteId core_system
```
Route packs are manifests for cacheable route loading. They do not call a model
and do not write live runtime state unless an explicit output path is supplied.
### 5. Run An Artifact-Backed Workflow
Create, simulate, verify, and collect a local workflow artifact without adding it
to source control:
```powershell
.\scripts\agents-workflow.ps1 -Action New -WorkflowId "example"
.\scripts\agents-workflow.ps1 -Action SimulateDispatch -WorkflowId "example" -Level 2
.\scripts\agents-workflow.ps1 -Action Verify -WorkflowId "example"
.\scripts\agents-workflow.ps1 -Action Collect -WorkflowId "example"
```
Live artifacts are local runtime state under `.agents/runtime/workflows/`.
`.workflow/` is blocked from deployment and release packages. Neither location
is deployable or releasable.
### 6. Manage Collaborator Windows
Collaborator windows are runtime Codex threads, not durable project files. The
controller maps a user objective to a department leader, creates or names one
leader window, sends a bounded assignment, and expects only a
`department_report`, `collaborator_report`, or `escalation_record`.

Example request styles:
```text
Create collaborator Greeting, responsible for greeting.
```
```text
Rename Greeting window to Documentation Desk.
```
```text
Dismiss Documentation Desk and verify it is no longer active.
```
Live thread ids, window titles, active lists, close evidence, and
`.agents/runtime/collaborators.jsonl` stay local. They are not deployable,
releasable, or public documentation content.
### 7. Deploy Into Another Repository
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
### 8. Export A Clean Release Package
```powershell
.\scripts\export-release-package.ps1
```
The release package excludes `.git/`, `.agents/runtime/`,
`.agents/runtime/workflows/`, `.workflow/`, local Codex configuration, local
environment configuration, local status records, and other machine-owned state.
The generated manifest records workflow version, source commit, included files,
file hashes, and package hash.
## Core Runtime System
Jared's AI Team 2.5.0 is a core runtime system for repo-local AI work. It unifies
route selection, enterprise dispatch, collaborator windows, context compact,
workflow artifacts, runtime evidence, deployment, validation, and release export
into one verifiable architecture.
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
  isolation details, and optional execution run references.
- Collaborator windows expose department leaders as named Codex work sessions;
  worker windows remain blocked unless an explicit override and escalation
  record exist.
- Invalid routing, authority violations, failed verification, or unsuitable model
  tiers must produce an escalation record.
The canonical files are:
- `docs/agents/core-system.yaml`
- `docs/agents/runtime-execution.yaml`
- `docs/agents/provider-adapters.yaml`
- `docs/agents/route-packs.yaml`
- `docs/agents/knowledge-footprint.yaml`
- `docs/agents/org.yaml`
- `docs/agents/model-policy.yaml`
- `docs/agents/dispatch.yaml`
- `docs/agents/workflow-artifacts.yaml`
- `docs/agents/context-compact.yaml`
- `docs/agents/collaborators.yaml`
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
| Runtime execution | Run records, step status, approval gates, result collection, escalations, and cleanup evidence. |
| Workflow artifacts | Local workflow state, packet ownership, approval gates, route guardrails, collection reports, and runtime blocklists. |
| Context compact | Required summary fields, raw transcript exclusion, subagent closeout counts, and runtime compact event boundary. |
| Collaborator windows | Department leader window mapping, thread operation evidence, worker window blocking, and runtime thread id exclusions. |
| Route pack | Deterministic route file selection, stable hashes, schema hash, cache key fields, and tool surface. |
The source of truth for these gates is `docs/agents/verify.yaml`.
## Repository Map
| Path | Purpose |
|---|---|
| `AGENTS.md` | Entry-point operating rules for Codex sessions. |
| `docs/agents/*.yaml` | Canonical core system, route, workflow, runtime execution, provider, deployment, verification, schema, MCP, dispatch, model, context compact, collaborator, and version rules. |
| `.agents/skills/project-isolation-workflow/` | Project-local Codex skill for isolation, deployment, memory, maintenance, and multi-agent work. |
| `docs/templates/agents/` | Source-neutral deployable template bundle. |
| `docs/runbooks/` | Operational procedures for deployment, closeout, audits, skills, sessions, and maintenance. |
| `scripts/validate.ps1` | Main local and CI validation entry point. |
| `scripts/agents-runtime.ps1` | Local runtime execution helper for run, step, approval, result, escalation, collect, verify, and cleanup actions. |
| `scripts/agents-workflow.ps1` | Local workflow artifact helper for new, verify, collect, simulate, and normalize actions. |
| `scripts/export-route-pack.ps1` | Deterministic route pack manifest exporter. |
| `scripts/deploy-agents-workflow.ps1` | Allowlisted deployment entry point for target repositories. |
| `scripts/export-release-package.ps1` | Clean release package exporter. |
| `scripts/update-github-updates.ps1` | Public GitHub update log generator. |
| `schemas/` | JSON Schema contracts used by validation. |
| `.github/workflows/` | GitHub Actions checkpoint and public update automation. |

For a detailed file-role matrix, see `docs/project-structure.md`.

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
  `.agents/runtime/executions/`, `.agents/runtime/knowledge/`,
  `.agents/runtime/route-packs/`, `.agents/runtime/tool-evidence/`,
  `.agents/runtime/deployments/`,
  `.agents/runtime/compact-events.jsonl`,
  `.agents/runtime/collaborators.jsonl`, `.workflow/`, `.codex/`, status
  records, evidence records, live thread ids, window state, secrets, and local
  environment state are not deployable workflow content.
- Deployment reports target-owned historical Agents files separately instead of
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
