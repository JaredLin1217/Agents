# GitHub Updates

This file is generated from git history after public branch pushes.
Do not hand-edit routine entries; change `scripts/update-github-updates.ps1` instead.

- Source branch: `master`
- Source commit analyzed: `5f7316f`
- Source commit date: `2026-06-09T06:15:46+08:00`
- Commit window: latest 12 non-merge commits

## Current Project Version

- Version: `2.6.1`
- Channel: `foundation-creation`
- Positioning: 2.6.1 stabilizes the foundation-creation workflow with official source traceability, runtime dry-run evidence boundaries, and size headroom without changing core workflow semantics.

## Recent Commits

### 2026-06-09 - `5f7316f`

Harden runtime boundary rules

- Author: `JaredLin1217`
- Shortstat: `8 files changed, 38 insertions(+), 14 deletions(-)`
- Files:
  - `docs/agents/collaborators.yaml`
  - `docs/agents/deploy.yaml`
  - `docs/agents/provider-adapters.yaml`
  - `docs/agents/workflows.yaml`
  - `docs/templates/agents/agents/collaborators.yaml`
  - `docs/templates/agents/agents/deploy.yaml`
  - `docs/templates/agents/agents/provider-adapters.yaml`
  - `docs/templates/agents/agents/workflows.yaml`

### 2026-06-09 - `268298c`

Fix ai-runtime provider naming drift and release artifact blocklist

- Author: `JaredLin1217`
- Shortstat: `4 files changed, 17 insertions(+), 6 deletions(-)`
- Files:
  - `docs/agents/verify.yaml`
  - `docs/templates/agents/agents/verify.yaml`
  - `scripts/export-release-package.ps1`
  - `scripts/validate.ps1`

### 2026-06-05 - `96d057b`

docs: update GitHub update log [skip ci]

- Author: `github-actions[bot]`
- Shortstat: `1 file changed, 20 insertions(+), 27 deletions(-)`
- Files:
  - `docs/github-updates.md`

### 2026-06-05 - `298142b`

Harden subagent cleanup residue removal

- Author: `JaredLin1217`
- Shortstat: `1 file changed, 46 insertions(+), 8 deletions(-)`
- Files:
  - `scripts/agents-cleanup.ps1`

### 2026-06-05 - `1a60c5b`

docs: update GitHub update log [skip ci]

- Author: `github-actions[bot]`
- Shortstat: `1 file changed, 25 insertions(+), 37 deletions(-)`
- Files:
  - `docs/github-updates.md`

### 2026-06-05 - `378aed3`

Add 2.5.1 cross-project runtime resilience

- Author: `JaredLin1217`
- Shortstat: `31 files changed, 2310 insertions(+), 344 deletions(-)`
- Files:
  - `.agents/skills/project-isolation-workflow/SKILL.md`
  - `CHANGELOG.md`
  - `README.md`
  - `docs/agents/deploy.yaml`
  - `docs/agents/runtime-execution.yaml`
  - `docs/agents/schemas.yaml`
  - `docs/agents/verify.yaml`
  - `docs/agents/version.yaml`

### 2026-06-03 - `4997195`

docs: update GitHub update log [skip ci]

- Author: `github-actions[bot]`
- Shortstat: `1 file changed, 24 insertions(+), 27 deletions(-)`
- Files:
  - `docs/github-updates.md`

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
