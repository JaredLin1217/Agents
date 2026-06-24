# Jared's AI Team

[![Checkpoint](https://github.com/JaredLin1217/Agents/actions/workflows/checkpoint.yml/badge.svg)](https://github.com/JaredLin1217/Agents/actions/workflows/checkpoint.yml)
[![Public Updates](https://github.com/JaredLin1217/Agents/actions/workflows/public-updates.yml/badge.svg)](https://github.com/JaredLin1217/Agents/actions/workflows/public-updates.yml)

Jared's AI Team is a repo-local AI Agents workflow system for Codex-style
engineering sessions. It provides compact routing rules, project-local
operating policy, deployable governance files, runtime evidence boundaries,
multi-agent coordination contracts, official-docs-first foundation creation,
and release packaging checks.

The repository is intentionally small and source-neutral. It is designed to be
deployed into target projects without copying local runtime state, live Codex
configuration, private thread identifiers, approval scratch files, or provider
repo history.

## Current Version

Current Agents workflow version: `2.6.2` (`foundation-creation`).

Canonical version source: `docs/agents/version.yaml`

Version positioning: 2.6.2 preserves the foundation-creation workflow while
adding repeatable runtime evidence capture, source freshness gates, and lower
validation maintenance hotspots.

## What This Project Provides

### Compact AI Runtime Routing

`docs/agents/ai-runtime.yaml` is the first routing layer after `AGENTS.md`. It
keeps default context small and expands only the named canonical YAML files
needed for the current task. This keeps ordinary turns fast while still
allowing deeper routes for deployment, multi-agent work, runtime evidence,
provider adapters, route packs, knowledge footprints, and foundation creation.

### Foundation Creation Governance

The `docs/agents/*.yaml` files define the project-owned operating standard:
policy, verification, deployment, organization, model tiering, dispatch,
schemas, runtime execution evidence, collaborator windows, context compaction,
foundation creation, and official OpenAI capability boundaries.

`docs/agents/openai-foundations.yaml` converts official OpenAI documentation
into project-native primitives for Structured Outputs, conversation state,
agent handoffs, Codex skills, subagents, prompt caching, predicted outputs, and
evaluation-backed release decisions.

### Runtime Evidence Without Repo Pollution

Runtime evidence is local by design. Files such as `.agents/runtime/**`,
`.workflow/**`, local Codex configuration, status files, temporary approval
records, and live collaborator state are ignored or blocklisted from release
packages and deployments unless a task explicitly authorizes a targeted runtime
operation.

### Deployable Workflow Package

The deployment system can install the AI Agents workflow into another
authorized repository using an allowlisted file set. It supports dry-run first
operation, target layout detection, target-owned state preservation, source
neutral template checks, and release package export.

### Multi-Agent and Enterprise Dispatch Contracts

The workflow includes optional two-layer dispatch for controller, department
leaders, and workers. It defines assignment fields, reports, scoring,
reconciliation, cleanup evidence, collaborator windows, and escalation
boundaries. Runtime multi-agent claims require live employee evidence.

## Repository Map

| Path | Purpose |
|---|---|
| `AGENTS.md` | Repo-local session rules and closeout contract. |
| `.agents/skills/project-isolation-workflow/` | Project-local skill for isolation, memory, deploy, agents, handoff, skills, and maintenance. |
| `docs/agents/` | Canonical AI Agents workflow YAML files. |
| `docs/runbooks/` | Human-readable operating procedures. |
| `docs/templates/agents/` | Source-neutral deployable template bundle. |
| `schemas/` | Lightweight schema contracts used by validation. |
| `scripts/` | Validation, deployment, release, route-pack, runtime, and cleanup helpers. |
| `tests/agents-governance-fixtures/` | Validation fixtures for schema and workflow contracts. |
| `artifacts/` | Provider-side audit and evaluation artifacts. |

## Read Order

1. `AGENTS.md`
2. `docs/agents/ai-runtime.yaml`
3. Route-specific canonical YAML named by `ai-runtime.yaml`
4. `docs/agents/verify.yaml` before state claims, edits, commits, deployment, or release
5. `docs/project-structure.md` for ownership and deployability boundaries

Do not use `docs/templates/agents/**` as the active rule source. Templates are
deployment material, not the current repo's live operating authority.

## Core Commands

Fast validation:

```powershell
.\scripts\validate.ps1
```

Full release readiness and quality score:

```powershell
.\scripts\validate.ps1 -Full -Score
```

Capture sanitized v2.6.2 runtime release evidence:

```powershell
.\scripts\capture-runtime-evidence.ps1 -OutputPath .\docs\evidence\releases\v2.6.2-runtime-evidence.json -Full
```

Deployment dry-run into an authorized target:

```powershell
.\scripts\deploy-agents-workflow.ps1 -TargetPath "D:\target\repo" -Mode core_bootstrap -LayoutProfile auto -DryRun
```

Upgrade an authorized target after dry-run review:

```powershell
.\scripts\deploy-agents-workflow.ps1 -TargetPath "D:\target\repo" -Mode core_bootstrap -LayoutProfile auto -Upgrade
```

Runtime execution evidence example:

```powershell
.\scripts\agents-runtime.ps1 -Action NewRun -RunId "example"
.\scripts\agents-runtime.ps1 -Action AddStep -RunId "example" -Step "read_only"
.\scripts\agents-runtime.ps1 -Action AddResult -RunId "example" -Result "completed" -Summary "read-only example completed"
.\scripts\agents-runtime.ps1 -Action Verify -RunId "example"
.\scripts\agents-runtime.ps1 -Action Cleanup -RunId "example"
```

Closed subagent residue verification:

```powershell
.\scripts\agents-cleanup.ps1 -Action Verify -RuntimeIds "<runtime-id>" -ParentThreadId "<parent-runtime-id>"
.\scripts\agents-cleanup.ps1 -Action Cleanup -RuntimeIds "<runtime-id>" -ParentThreadId "<parent-runtime-id>" -Force
```

Deterministic route-pack export:

```powershell
.\scripts\export-route-pack.ps1 -RouteId core_system
```

Release package export:

```powershell
.\scripts\export-release-package.ps1
```

## Validation Coverage

The main validator covers:

- Lightweight YAML syntax and required canonical files
- AI runtime compact routing and expand-only route behavior
- Canonical schema contract checks
- Enterprise dispatch, workflow artifacts, context compaction, collaborator windows, and core runtime integrity
- Runtime/local boundary checks
- Durable English-only and placeholder gates
- Exact-pair drift checks for deployable mirrors
- Deployment manifest, blocklist, source-neutral template, and self-test checks
- Multi-agent workflow integrity and cleanup evidence contracts
- CI workflow stability
- P0-P5 readiness evidence
- Size gates for routing files, scripts, project skill, and tracked repository footprint
- Release package export checks

## Operating Boundaries

- Runtime state is local evidence, not deployable project source.
- Target deployments preserve target-owned state by default.
- Hard-isolation claims require current runtime, tool, OS, account, or cloud
  enforcement evidence.
- Runtime multi-agent claims require live employee evidence and cleanup
  reconciliation.
- OpenAI API, Apps SDK, Codex, Agents SDK, model, and tool guidance should
  use official OpenAI developer documentation first.
- Global memory and global/system skills are off by default unless explicitly
  requested.

## Quality Target

The project aims for a small, portable, evidence-backed AI Agents operating
standard:

- Compact default context
- Clear route expansion
- Source-neutral deployment
- Runtime evidence without repository pollution
- Repeatable validation and release checks
- Explicit claim boundaries for multi-agent execution and hard isolation
- Schema-first feature creation from official OpenAI capabilities
- Latency, cost, fallback, and evaluation gates before release

## License

Copyright 2026 Yu-Jie, Lin.

Licensed under the Apache License, Version 2.0. See `LICENSE` for the full
license text and `NOTICE` for the project notice and additional disclaimer.

Unless required by applicable law or agreed to in writing, this repository is
provided on an "AS IS" basis, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
either express or implied.
