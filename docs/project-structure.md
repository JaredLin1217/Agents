# Source Repo Structure
This source repo owns the canonical AI Agents workflow: repo-local routing,
deployable governance, project-local skills, runtime boundaries, validation
gates, deployment templates, and extension points.
## Read Order
1. `AGENTS.md`
2. `docs/agents/ai-runtime.yaml`
3. `docs/agents/workflows.yaml` when routing or multi-agent behavior matters
4. `docs/agents/org.yaml`, `docs/agents/model-policy.yaml`, and
   `docs/agents/dispatch.yaml` only for enterprise dispatch work
5. `docs/agents/workflow-artifacts.yaml` only for artifact-backed workflow work
6. `docs/agents/context-compact.yaml` only for compaction or resume work
7. `docs/agents/collaborators.yaml` only for Codex collaborator window work
8. `docs/agents/policy.yaml` for isolation or boundary claims
9. `docs/agents/verify.yaml` before claims, commits, deployments, or releases
10. `docs/agents/schemas.yaml` for assignments, reports, status, or templates
11. `docs/agents/mcp.yaml` when optional integrations matter
12. `docs/agents/version.yaml` for compatibility
13. `docs/agents/deploy.yaml` for authorized target deployment
## Role Matrix
| Area | Role | Deploy policy |
|---|---|---|
| `AGENTS.md` | session router | deploy |
| `.agents/skills/project-isolation-workflow/` | project-local skill | deploy |
| `.agents/runtime/` | ignored coordination/runtime state | never deploy |
| `.agents/runtime/workflows/`, `.workflow/` | local workflow artifacts and import alias | never deploy |
| `.agents/runtime/collaborators.jsonl` | local collaborator window/thread state | never deploy |
| `docs/agents/*.yaml` | canonical governance rules | deploy |
| `docs/agents/org.yaml`, `docs/agents/model-policy.yaml`, `docs/agents/dispatch.yaml` | enterprise dispatch overlay | deploy |
| `docs/agents/workflow-artifacts.yaml` | supervised workflow artifact route | deploy |
| `docs/agents/context-compact.yaml` | context compact route | deploy |
| `docs/agents/collaborators.yaml` | collaborator window dispatch route | deploy |
| `docs/runbooks/*.md` | procedure entry points | mode-based deploy |
| `docs/templates/agents/` | source-neutral deploy bundle | `template_provider_mode` only |
| `docs/memory/`, `docs/decisions/` | provider-local knowledge | target-owned / do not deploy rows |
| `docs/agents/decisions/` | workflow structure decisions | provider source only |
| `schemas/`, `scripts/`, `tests/`, `mcp/` | contracts, checks, fixtures, capability registry | provider source only until explicitly deployed |
| `artifacts/`, `.github/workflows/` | audits/evals and CI | provider source only |
| `.codex/`, status, validation records | local/runtime state | never deploy |
Do not deploy source `.agents/runtime/`, `.agents/runtime/workflows/`,
`.agents/runtime/collaborators.jsonl`, `.workflow/`, `.codex/config.toml`,
`.codex/environments/*.toml`, source memory rows, decisions, status,
live thread ids, collaborator window state, or validation history by default.
## V2 Structure Rule
V2 structure changes must preserve mirror pairs and deployment rules until drift
checks are updated. Large moves of runbooks, templates, decisions, or memory docs
belong in dedicated changes, not mixed with validation, MCP, or CI work.
The `v2.3.0` collaborator window layer is an optional overlay on top of
enterprise dispatch. Simple answer, scoped edit, plain deploy, and release tasks
still use the minimal route from `docs/agents/ai-runtime.yaml` and should not
load organization, workflow artifact, context compact, or collaborator files
unless the task is about departments, employees, delegation, model binding,
artifact packets, approval gates, collection, compaction, resume, named Codex
threads, window rename, or collaborator archive/close.
