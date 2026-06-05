# GitHub Updates

This file is generated from git history after public branch pushes.
Do not hand-edit routine entries; change `scripts/update-github-updates.ps1` instead.

- Source branch: `main`
- Source commit analyzed: `pending local update`
- Source commit date: `2026-06-05T00:00:00+08:00`
- Commit window: latest 12 non-merge commits

## Current Project Version

- Version: `2.5.1`
- Channel: `core-runtime`
- Positioning: Core Runtime System with cross-project runtime resilience for recoverable windows, layout-aware deployment, target dirty guards, isolated batch validation, and mandatory cleanup capability.

## Pending Local Update

### 2026-06-05 - local

Add 2.5.1 cross-project runtime resilience patch

- Strengthens deployment layout profiles for root and dot-agents targets.
- Adds target dirty snapshot evidence and unexpected file guards.
- Adds per-project/per-run temp roots for validation and route-pack export.
- Makes cleanup capability mandatory in deployed core workflow files.
- Refreshes the public README around repo-local governance and customer project benefits.

## Recent Commits

### 2026-06-04 - `9c9fde0`

Improve public README value narrative

- Author: `JaredLin1217`
- Shortstat: `5 files changed, 241 insertions(+), 286 deletions(-)`
- Files:
  - `README.md`
  - `docs/agents/deploy.yaml`
  - `docs/templates/agents/agents/deploy.yaml`
  - `scripts/deploy-agents-workflow.ps1`
  - `scripts/validate.ps1`

### 2026-06-03 - `08f743e`

docs: update GitHub update log [skip ci]

- Author: `github-actions[bot]`
- Shortstat: `1 file changed, 26 insertions(+), 27 deletions(-)`
- Files:
  - `docs/github-updates.md`

### 2026-06-04 - `e6d2543`

Add AI runtime schema validation

- Author: `JaredLin1217`
- Shortstat: `7 files changed, 43 insertions(+), 5 deletions(-)`
- Files:
  - `docs/agents/ai-runtime.yaml`
  - `docs/agents/provider-adapters.yaml`
  - `docs/templates/agents/agents/ai-runtime.yaml`
  - `docs/templates/agents/agents/provider-adapters.yaml`
  - `schemas/agents-ai-runtime.schema.json`
  - `schemas/agents-provider-adapters.schema.json`
  - `scripts/validate.ps1`

### 2026-06-03 - `cde5335`

docs: update GitHub update log [skip ci]

- Author: `github-actions[bot]`
- Shortstat: `1 file changed, 27 insertions(+), 27 deletions(-)`
- Files:
  - `docs/github-updates.md`

### 2026-06-04 - `5a59786`

Add 2.5.0 core runtime system

- Author: `JaredLin1217`
- Shortstat: `58 files changed, 2763 insertions(+), 1186 deletions(-)`
- Files:
  - `.agents/skills/project-isolation-workflow/SKILL.md`
  - `.gitignore`
  - `CHANGELOG.md`
  - `README.md`
  - `docs/agents/ai-runtime.yaml`
  - `docs/agents/collaborators.yaml`
  - `docs/agents/context-compact.yaml`
  - `docs/agents/core-system.yaml`

### 2026-06-03 - `ca7f5cf`

docs: update GitHub update log [skip ci]

- Author: `github-actions[bot]`
- Shortstat: `1 file changed, 43 insertions(+), 36 deletions(-)`
- Files:
  - `docs/github-updates.md`

### 2026-06-03 - `019f3a7`

Add 2.3.0 collaborator window dispatch layer

- Author: `JaredLin1217`
- Shortstat: `38 files changed, 1368 insertions(+), 356 deletions(-)`
- Files:
  - `.agents/skills/project-isolation-workflow/SKILL.md`
  - `.gitignore`
  - `CHANGELOG.md`
  - `README.md`
  - `docs/agents/ai-runtime.yaml`
  - `docs/agents/collaborators.yaml`
  - `docs/agents/deploy.yaml`
  - `docs/agents/dispatch.yaml`

### 2026-06-03 - `aef5f67`

Prevent deploying target-local Codex environment templates

- Author: `JaredLin1217`
- Shortstat: `14 files changed, 179 insertions(+), 34 deletions(-)`
- Files:
  - `.codex/environments/environment.template.toml`
  - `.gitignore`
  - `docs/agents/deploy.yaml`
  - `docs/agents/policy.yaml`
  - `docs/agents/verify.yaml`
  - `docs/project-structure.md`
  - `docs/templates/agents/agents/deploy.yaml`
  - `docs/templates/agents/agents/policy.yaml`

### 2026-06-03 - `bb25403`

docs: update GitHub update log [skip ci]

- Author: `github-actions[bot]`
- Shortstat: `1 file changed, 27 insertions(+), 23 deletions(-)`
- Files:
  - `docs/github-updates.md`

### 2026-06-03 - `7cdf0fc`

Add 2.2.1 context compact layer

- Author: `JaredLin1217`
- Shortstat: `26 files changed, 725 insertions(+), 423 deletions(-)`
- Files:
  - `CHANGELOG.md`
  - `README.md`
  - `docs/agents/ai-runtime.yaml`
  - `docs/agents/context-compact.yaml`
  - `docs/agents/deploy.yaml`
  - `docs/agents/schemas.yaml`
  - `docs/agents/verify.yaml`
  - `docs/agents/version.yaml`

### 2026-06-03 - `a020590`

docs: update GitHub update log [skip ci]

- Author: `github-actions[bot]`
- Shortstat: `1 file changed, 27 insertions(+), 26 deletions(-)`
- Files:
  - `docs/github-updates.md`

### 2026-06-03 - `53bf8c8`

docs: tighten subagent cleanup workflow

- Author: `JaredLin1217`
- Shortstat: `10 files changed, 125 insertions(+), 72 deletions(-)`
- Files:
  - `README.md`
  - `docs/agents/schemas.yaml`
  - `docs/agents/workflows.yaml`
  - `docs/runbooks/multi-agent-workflow.md`
  - `docs/runtime-multi-agent-validation.template.md`
  - `docs/templates/agents/agents/schemas.yaml`
  - `docs/templates/agents/agents/workflows.yaml`
  - `docs/templates/agents/multi-agent-workflow.md`
