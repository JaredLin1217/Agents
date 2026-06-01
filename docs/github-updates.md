# GitHub Updates

This file is generated from git history after public branch pushes.
Do not hand-edit routine entries; change `scripts/update-github-updates.ps1` instead.

- Source branch: `main`
- Source commit analyzed: `c6693aa`
- Source commit date: `2026-06-01T08:09:43+08:00`
- Commit window: latest 20 non-merge commits

## Recent Commits

### 2026-06-01 - `c6693aa`

Improve public GitHub documentation

- Author: `JaredLin1217`
- Shortstat: `11 files changed, 477 insertions(+), 5 deletions(-)`
- Files:
  - `.github/ISSUE_TEMPLATE/bug_report.yml`
  - `.github/ISSUE_TEMPLATE/config.yml`
  - `.github/ISSUE_TEMPLATE/deployment.yml`
  - `.github/ISSUE_TEMPLATE/documentation.yml`
  - `.github/pull_request_template.md`
  - `CHANGELOG.md`
  - `CODE_OF_CONDUCT.md`
  - `CONTRIBUTING.md`
  - `README.md`
  - `SECURITY.md`
  - `SUPPORT.md`

### 2026-06-01 - `79675b8`

Add compact Agents runtime routing

- Author: `JaredLin1217`
- Shortstat: `14 files changed, 193 insertions(+), 86 deletions(-)`
- Files:
  - `.agents/skills/project-isolation-workflow/SKILL.md`
  - `AGENTS.md`
  - `docs/agents/ai-runtime.yaml`
  - `docs/agents/deploy.yaml`
  - `docs/agents/verify.yaml`
  - `docs/agents/workflows.yaml`
  - `docs/templates/agents/AGENTS.md`
  - `docs/templates/agents/agents/ai-runtime.yaml`
  - `docs/templates/agents/agents/deploy.yaml`
  - `docs/templates/agents/agents/verify.yaml`
  - `docs/templates/agents/agents/workflows.yaml`
  - `docs/templates/agents/skills/project-isolation-workflow/SKILL.md`

### 2026-06-01 - `6243de5`

Harden agents deployment handoff validation

- Author: `JaredLin1217`
- Shortstat: `13 files changed, 319 insertions(+), 26 deletions(-)`
- Files:
  - `AGENTS.md`
  - `docs/agents/deploy.yaml`
  - `docs/agents/verify.yaml`
  - `docs/deployment-feedback.template.md`
  - `docs/runbooks/agents-deployment.md`
  - `docs/templates/agents/AGENTS.md`
  - `docs/templates/agents/README.md`
  - `docs/templates/agents/agents-deployment.md`
  - `docs/templates/agents/agents/deploy.yaml`
  - `docs/templates/agents/agents/verify.yaml`
  - `docs/templates/agents/deployment-feedback.template.md`
  - `scripts/deploy-agents-workflow.ps1`

### 2026-06-01 - `0406239`

Optimize v2 workflow package

- Author: `JaredLin1217`
- Shortstat: `24 files changed, 582 insertions(+), 1009 deletions(-)`
- Files:
  - `.agents/skills/project-isolation-workflow/SKILL.md`
  - `AGENTS.md`
  - `docs/agents/decisions/v2-checkpoint-package.md`
  - `docs/agents/decisions/v2-readiness-audit.md`
  - `docs/agents/decisions/v2-structure-roadmap.md`
  - `docs/agents/deploy.yaml`
  - `docs/agents/mcp.yaml`
  - `docs/agents/verify.yaml`
  - `docs/agents/workflows.yaml`
  - `docs/project-structure.md`
  - `docs/runbooks/multi-agent-workflow.md`
  - `docs/templates/agents/AGENTS.md`

### 2026-05-31 - `66a71cf`

Require workflow scoring batch contract

- Author: `JaredLin1217`
- Shortstat: `1 file changed, 1 insertion(+)`
- Files:
  - `schemas/agents-workflows.schema.json`

### 2026-05-31 - `efb110f`

Require compact verification guardrails

- Author: `JaredLin1217`
- Shortstat: `2 files changed, 4 insertions(+)`
- Files:
  - `schemas/agents-verify.schema.json`
  - `scripts/validate.ps1`

### 2026-05-31 - `b829ef3`

Verify deployed gitignore runtime coverage

- Author: `JaredLin1217`
- Shortstat: `2 files changed, 40 insertions(+)`
- Files:
  - `scripts/deploy-agents-workflow.ps1`
  - `scripts/validate.ps1`

### 2026-05-31 - `1c1956a`

Harden verification evidence contracts

- Author: `JaredLin1217`
- Shortstat: `1 file changed, 12 insertions(+)`
- Files:
  - `schemas/agents-verify.schema.json`

### 2026-05-31 - `cde76c7`

Harden deploy schema layout contracts

- Author: `JaredLin1217`
- Shortstat: `1 file changed, 27 insertions(+)`
- Files:
  - `schemas/agents-deploy.schema.json`

### 2026-05-31 - `3370f72`

Derive deployment self-test namespace

- Author: `JaredLin1217`
- Shortstat: `4 files changed, 21 insertions(+), 3 deletions(-)`
- Files:
  - `docs/agents/verify.yaml`
  - `docs/templates/agents/agents/verify.yaml`
  - `scripts/deploy-agents-workflow.ps1`
  - `scripts/validate.ps1`

### 2026-05-31 - `bc7f3a0`

Harden schema semantic contracts

- Author: `JaredLin1217`
- Shortstat: `1 file changed, 78 insertions(+), 1 deletion(-)`
- Files:
  - `schemas/agents-schemas.schema.json`

### 2026-05-31 - `d185d3e`

Harden policy workflow schema contracts

- Author: `JaredLin1217`
- Shortstat: `3 files changed, 69 insertions(+), 4 deletions(-)`
- Files:
  - `schemas/agents-policy.schema.json`
  - `schemas/agents-workflows.schema.json`
  - `tests/agents-governance-fixtures/schema-contracts/workflows.valid.yaml`

### 2026-05-31 - `0aa633d`

Harden deploy and verify contracts

- Author: `JaredLin1217`
- Shortstat: `2 files changed, 73 insertions(+)`
- Files:
  - `schemas/agents-deploy.schema.json`
  - `schemas/agents-verify.schema.json`

### 2026-05-31 - `21a242f`

Tighten v2 version contract

- Author: `JaredLin1217`
- Shortstat: `1 file changed, 27 insertions(+), 1 deletion(-)`
- Files:
  - `schemas/agents-version.schema.json`

### 2026-05-31 - `0024f87`

Validate deployment self-test scenarios

- Author: `JaredLin1217`
- Shortstat: `3 files changed, 52 insertions(+), 2 deletions(-)`
- Files:
  - `docs/agents/deploy.yaml`
  - `docs/templates/agents/agents/deploy.yaml`
  - `scripts/validate.ps1`

### 2026-05-31 - `e968a44`

Validate evidence schema parity

- Author: `JaredLin1217`
- Shortstat: `3 files changed, 60 insertions(+)`
- Files:
  - `docs/agents/schemas.yaml`
  - `docs/templates/agents/agents/schemas.yaml`
  - `scripts/validate.ps1`

### 2026-05-31 - `21046d4`

Validate agent ledger compatibility

- Author: `JaredLin1217`
- Shortstat: `3 files changed, 62 insertions(+), 3 deletions(-)`
- Files:
  - `docs/agents/verify.yaml`
  - `docs/templates/agents/agents/verify.yaml`
  - `scripts/validate.ps1`

### 2026-05-31 - `8787f93`

Normalize multi-agent ledger schema

- Author: `JaredLin1217`
- Shortstat: `3 files changed, 10 insertions(+), 4 deletions(-)`
- Files:
  - `docs/agents/schemas.yaml`
  - `docs/templates/agents/agents/schemas.yaml`
  - `scripts/validate.ps1`

### 2026-05-31 - `5854ea0`

Harden v2 deployment validation

- Author: `JaredLin1217`
- Shortstat: `22 files changed, 514 insertions(+), 45 deletions(-)`
- Files:
  - `.github/workflows/README.md`
  - `.github/workflows/checkpoint.yml`
  - `.gitignore`
  - `docs/agent-assignment.template.md`
  - `docs/agents/decisions/v2-checkpoint-package.md`
  - `docs/agents/decisions/v2-readiness-audit.md`
  - `docs/agents/deploy.yaml`
  - `docs/agents/policy.yaml`
  - `docs/agents/schemas.yaml`
  - `docs/agents/verify.yaml`
  - `docs/agents/workflows.yaml`
  - `docs/runbooks/multi-agent-workflow.md`

### 2026-05-31 - `9d1f00f`

Use redirected checkpoint runner

- Author: `JaredLin1217`
- Shortstat: `2 files changed, 3 insertions(+), 3 deletions(-)`
- Files:
  - `.github/workflows/checkpoint.yml`
  - `scripts/validate.ps1`
