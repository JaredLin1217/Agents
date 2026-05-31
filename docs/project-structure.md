# Source Repo Structure

This source repo owns the canonical AI Agents workflow architecture:
repo-local routing, deployable governance rules, project-local skills,
runtime boundaries, validation gates, deployment templates, and future
extension points.

## Read Order

1. `AGENTS.md`
2. `docs/agents/workflows.yaml`
3. `docs/agents/policy.yaml`
4. `docs/agents/verify.yaml`
5. `docs/agents/schemas.yaml` only for assignments, reports, status, or templates
6. `docs/agents/deploy.yaml` only for authorized target deployment

## Role Matrix

| Area | Role | Deploy policy |
|---|---|---|
| `AGENTS.md` | Provider and target router | deploy |
| `.agents/skills/project-isolation-workflow/` | Project-local skill | deploy |
| `.agents/runtime/` | Project-local runtime coordination | never deploy |
| `docs/agents/*.yaml` | Canonical Agents governance rules | deploy |
| `docs/runbooks/*.md` | Task entry points | mode-based deploy |
| `docs/templates/agents/` | Provider deploy bundle | `template_provider_mode` only |
| `docs/memory/`, `docs/decisions/` | Provider-local knowledge | target-owned / do not deploy rows |
| `docs/agents/decisions/` | Agents workflow structure decisions | provider source only |
| `schemas/` | Machine-readable policy contracts | provider source only until deploy rules include them |
| `scripts/` | Local validation and maintenance commands | provider source only until deploy rules include them |
| `tests/` | Fixtures and automated validation tests | provider source only |
| `mcp/` | MCP capability registry and boundaries | provider source only until explicitly deployed |
| `artifacts/` | Trace, eval, and audit artifact boundary | runtime outputs ignored unless promoted |
| `.github/workflows/` | CI delivery lane | provider source only |
| `.codex/`, status, validation records | Local runtime state | never deploy |

- `AGENTS.md`: every-session router.
- `.agents/skills/project-isolation-workflow/`: project-local skill.
- `.agents/runtime/`: ignored coordination ledger and runtime state.
- `docs/agents/*.yaml`: canonical Agents governance rules.
- `docs/runbooks/*.md`: short entry points.
- `docs/templates/agents/`: source-neutral deploy bundle.
- `docs/memory/`, `docs/decisions/`: source-local lessons and decisions.
- `docs/agents/decisions/`: v2 workflow structure and governance decisions.
- `schemas/`: contracts for canonical YAML and future validation gates.
- `scripts/`: local executable checks and maintenance commands.
- `tests/`: fixtures and automated tests for Agents governance behavior.
- `mcp/`: project-level capability registry before MCP implementation.
- `artifacts/`: boundary for traces, evals, and audit outputs.
- `.github/workflows/`: CI workflows for stable local validation gates.

Do not deploy source `.agents/runtime/`, `.codex/config.toml`, `.codex/environments/environment.toml`, source memory rows, decisions, status, or validation history by default.

## V2 Structure Rule

V2 structure changes must preserve existing mirror pairs and deployment rules
until the corresponding drift checks are updated. Large moves of runbooks,
templates, decisions, or memory docs should be handled as dedicated changes,
not mixed with validation, MCP, or CI implementation.
