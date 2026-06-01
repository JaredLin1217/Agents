# Jared's AI Team

[![Checkpoint](https://github.com/JaredLin1217/Agents/actions/workflows/checkpoint.yml/badge.svg)](https://github.com/JaredLin1217/Agents/actions/workflows/checkpoint.yml)
[![Public Updates](https://github.com/JaredLin1217/Agents/actions/workflows/public-updates.yml/badge.svg)](https://github.com/JaredLin1217/Agents/actions/workflows/public-updates.yml)

Portable, project-isolated Agents workflow governance for Codex projects.

This repository packages a source-controlled operating system for AI-agent work:
repo-local routing rules, deployable templates, project-local skills, validation
gates, deployment safety rules, runtime boundaries, and handoff documents that
can be installed into another repository without copying local state.

## Why This Exists

AI coding agents work best when the repository itself explains how work should
be routed, verified, handed off, and deployed. This project keeps that guidance
inside the repo instead of relying on global memory, hidden local settings, or
untracked session habits.

The main goals are:

- Keep project behavior portable across Codex sessions and target repositories.
- Minimize routine LLM context by loading only the rules needed for the task.
- Separate deployable workflow files from target-owned runtime, secrets, memory,
  Git metadata, and local environment state.
- Provide repeatable validation gates before edits, commits, deployments, and
  releases.
- Make multi-agent work auditable with explicit ownership, reports, and closeout
  boundaries.

## What Is Included

| Area | Purpose |
|---|---|
| `AGENTS.md` | Entry-point operating rules for Codex sessions. |
| `docs/agents/*.yaml` | Canonical governance, enterprise dispatch, model policy, deployment, verification, schema, MCP, and version rules. |
| `.agents/skills/project-isolation-workflow/` | Project-local Codex skill for isolation, deployment, memory, maintenance, and multi-agent workflows. |
| `docs/templates/agents/` | Source-neutral bundle that can be deployed into another repository. |
| `docs/runbooks/` | Human-readable procedures for deployment, closeout, audits, skills, sessions, and maintenance. |
| `scripts/validate.ps1` | Fast and full validation gates for policy and deployment integrity. |
| `scripts/deploy-agents-workflow.ps1` | Allowlisted deployment entry point for authorized target repositories. |
| `scripts/export-release-package.ps1` | Builds a clean release package with a manifest, commit, file hashes, and blocked local-state exclusions. |
| `scripts/update-github-updates.ps1` | Generates the public GitHub update log from recent git history. |
| `schemas/` | Lightweight JSON Schema contracts used by validation. |
| `.github/workflows/checkpoint.yml` | GitHub Actions checkpoint for pushes and pull requests. |
| `.github/workflows/public-updates.yml` | GitHub Actions automation that refreshes `docs/github-updates.md` after branch pushes. |

## Quick Start

Read the operating entry points in this order:

1. `AGENTS.md`
2. `docs/agents/ai-runtime.yaml`
3. `docs/agents/workflows.yaml` only when routing or multi-agent behavior matters
4. `docs/agents/org.yaml`, `docs/agents/model-policy.yaml`, and
   `docs/agents/dispatch.yaml` only for enterprise dispatch work
5. `docs/agents/verify.yaml` before claims, commits, deployments, or releases
6. `docs/agents/deploy.yaml` before deploying into another repository

Run the fast local check:

```powershell
.\scripts\validate.ps1
```

Run the broader release/deployment audit:

```powershell
.\scripts\validate.ps1 -Full
```

Export a clean release package:

```powershell
.\scripts\export-release-package.ps1
```

The package excludes Git metadata, runtime state, local Codex configuration,
local environment configuration, and source validation records. Its manifest
records the workflow version, source commit, included files, file hashes, and
package hash.

## Deploy Into Another Repository

Always dry-run first against an exact authorized target path:

```powershell
.\scripts\deploy-agents-workflow.ps1 -TargetPath "D:\target\repo" -Mode core_bootstrap -DryRun
```

Upgrade an existing target after reviewing the dry-run plan:

```powershell
.\scripts\deploy-agents-workflow.ps1 -TargetPath "D:\target\repo" -Mode core_bootstrap -Upgrade
```

Available modes:

- `core_bootstrap`: deploys the root rules, canonical Agents YAML, project skill,
  gitignore fragment, and core runbooks.
- `full_workflow`: adds assignment, status, evidence, feedback, memory starter,
  and maintenance templates.
- `template_provider_mode`: adds the recursive template bundle so the target can
  redeploy the workflow.

Deployment is allowlist-based. It preserves target layout, app code, `.git`,
`.codex`, runtime files, secrets, target-owned memory, and local environment
state unless the user explicitly authorizes a narrower targeted action.

## Operating Boundaries

This repository is designed around strict source/runtime separation:

- Global Memory is not used unless the user explicitly asks for it.
- Global/system skills are not used by default.
- Project-local skills under `.agents/skills/` are part of this repo.
- `.agents/runtime/`, `.codex/`, status records, evidence records, secrets, and
  local environment state are not deployable workflow content.
- Deployment reports target-owned legacy Agents files separately instead of
  treating a dirty target repository as a failed deployment.

## Validation Model

The validation profile is chosen by claim scope:

- answer-only: no command required when no current-state claim is made
- scoped edits: fast status, diff, and focused checks
- policy/template edits: mirror-pair and durable-rule checks
- commit/tag/push checkpoints: staged hygiene, line endings, placeholders, and
  runtime/local staging checks
- deploy/release audits: deployment self-test, template integrity, schema
  coverage, size gates, and target handoff checks
- enterprise dispatch: department leader assignment, internal delegation,
  model tier references, report routing, and escalation records

The full source of truth for profile selection is `docs/agents/verify.yaml`.

## Repository Map

For a detailed file-role matrix, see `docs/project-structure.md`.

Supporting documentation:

- `docs/runbooks/agents-deployment.md`
- `docs/runbooks/multi-agent-workflow.md`
- `docs/runbooks/repository-maintenance.md`
- `docs/runbooks/task-closeout.md`
- `docs/github-updates.md`
- `scripts/README.md`
- `schemas/README.md`
- `mcp/README.md`

## Public Project Status

This project is public and intended to be used as an Agents workflow provider.
It is not an application framework or runtime service. The primary interface is
the repository content, validation script, and deployment script.

Recent public repository changes are summarized in `docs/github-updates.md`.
That file is regenerated by GitHub Actions after pushes to `main` or `master`.

## Current Workflow Version

Current Agents workflow version: `2.1.0` (`v2`).

The canonical source is `docs/agents/version.yaml`. Deployment extracts this
version metadata from that file, copies the matching version file into the
target's deployed file set, and records the aligned version in the deployment
report.

Version `2.1.0` adds the Enterprise Dispatch Layer: controller-to-department
leader assignment, leader-owned internal delegation, tier-based model policy,
department reports, escalation records, and release package export.

## Contributing

See `CONTRIBUTING.md` for local workflow rules, validation expectations, and
what should not be committed.

See `CODE_OF_CONDUCT.md` for participation expectations.

## Security

See `SECURITY.md` for reporting guidance. Do not publish secrets, local Codex
configuration, target credentials, or private deployment evidence in issues.

## License

Copyright 2026 Yu-Jie, Lin.

Licensed under the Apache License, Version 2.0. See `LICENSE` for the full
license text and `NOTICE` for the project notice and additional disclaimer.

Unless required by applicable law or agreed to in writing, this repository is
provided on an "AS IS" basis, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
either express or implied.
