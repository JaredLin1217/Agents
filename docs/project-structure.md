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
8. `docs/agents/core-system.yaml` only for core runtime boundary work
9. `docs/agents/runtime-execution.yaml` only for execution evidence work
10. `docs/agents/provider-adapters.yaml` only for provider capability work
11. `docs/agents/route-packs.yaml` only for route pack work
12. `docs/agents/knowledge-footprint.yaml` only for cross-window resume work
13. `docs/agents/policy.yaml` for isolation or boundary claims
14. `docs/agents/verify.yaml` before claims, commits, deployments, or releases
15. `docs/agents/schemas.yaml` for assignments, reports, status, or templates
16. `docs/agents/mcp.yaml` when optional integrations matter
17. `docs/agents/version.yaml` for core runtime version metadata
18. `docs/agents/deploy.yaml` for authorized target deployment
## Role Matrix
| Area | Role | Deploy policy |
|---|---|---|
| `AGENTS.md` | session router | deploy |
| `.agents/skills/project-isolation-workflow/` | project-local skill | deploy |
| `.agents/runtime/` | ignored coordination/runtime state | never deploy |
| `.agents/runtime/workflows/`, `.workflow/` | local workflow artifacts and import alias | never deploy |
| `.agents/runtime/collaborators.jsonl` | local collaborator window/thread state | never deploy |
| `docs/agents/*.yaml` | canonical governance rules | deploy |
| `docs/agents/org.yaml`, `docs/agents/model-policy.yaml`, `docs/agents/dispatch.yaml` | enterprise dispatch runtime | deploy |
| `docs/agents/workflow-artifacts.yaml` | supervised workflow artifact route | deploy |
| `docs/agents/context-compact.yaml` | context compact route | deploy |
| `docs/agents/collaborators.yaml` | collaborator window dispatch route | deploy |
| `docs/agents/core-system.yaml` | core runtime system boundary | deploy |
| `docs/agents/runtime-execution.yaml` | execution run evidence route | deploy |
| `docs/agents/provider-adapters.yaml` | provider capability and tier map route | deploy |
| `docs/agents/route-packs.yaml` | deterministic minimal route pack route | deploy |
| `docs/agents/knowledge-footprint.yaml` | cross-window resume evidence route | deploy |
| `docs/runbooks/*.md` | procedure entry points | mode-based deploy |
| `docs/templates/agents/` | source-neutral deploy bundle | `template_provider_mode` only |
| `docs/memory/`, `docs/decisions/` | provider-local knowledge | target-owned / do not deploy rows |
| `docs/agents/decisions/` | workflow structure decisions | provider source only |
| `schemas/`, `scripts/`, `tests/`, `mcp/` | contracts, checks, fixtures, capability registry | provider source only until explicitly deployed |
| `artifacts/`, `.github/workflows/` | audits/evals and CI | provider source only |
| `.codex/`, status, validation records | local/runtime state | never deploy |
Do not deploy source `.agents/runtime/`, `.agents/runtime/workflows/`,
`.agents/runtime/executions/`, `.agents/runtime/knowledge/`,
`.agents/runtime/route-packs/`, `.agents/runtime/tool-evidence/`,
`.agents/runtime/deployments/`, `.agents/runtime/collaborators.jsonl`,
`.workflow/`, `.codex/config.toml`,
`.codex/environments/*.toml`, source memory rows, decisions, status,
live thread ids, collaborator window state, or validation history by default.
## Core Runtime Structure Rule
Core runtime structure changes must preserve mirror pairs, deployment rules,
schema contracts, runtime blocklists, and route-pack compactness until drift
checks are updated. Large moves of runbooks, templates, decisions, or memory docs
belong in dedicated changes, not mixed with validation, MCP, or CI work.
Simple answer, scoped edit, plain deploy, and release tasks still use the
minimal route from `docs/agents/ai-runtime.yaml` and should not load
organization, workflow artifact, context compact, collaborator, core-system,
runtime-execution, provider-adapter, route-pack, or knowledge-footprint files
unless the task is about those named routes.
