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
5. `docs/agents/policy.yaml` for isolation or boundary claims
6. `docs/agents/verify.yaml` before claims, commits, deployments, or releases
7. `docs/agents/schemas.yaml` for assignments, reports, status, or templates
8. `docs/agents/mcp.yaml` when optional integrations matter
9. `docs/agents/version.yaml` for compatibility
10. `docs/agents/deploy.yaml` for authorized target deployment

## Role Matrix

| Area | Role | Deploy policy |
|---|---|---|
| `AGENTS.md` | session router | deploy |
| `.agents/skills/project-isolation-workflow/` | project-local skill | deploy |
| `.agents/runtime/` | ignored coordination/runtime state | never deploy |
| `docs/agents/*.yaml` | canonical governance rules | deploy |
| `docs/agents/org.yaml`, `docs/agents/model-policy.yaml`, `docs/agents/dispatch.yaml` | enterprise dispatch overlay | deploy |
| `docs/runbooks/*.md` | procedure entry points | mode-based deploy |
| `docs/templates/agents/` | source-neutral deploy bundle | `template_provider_mode` only |
| `docs/memory/`, `docs/decisions/` | provider-local knowledge | target-owned / do not deploy rows |
| `docs/agents/decisions/` | workflow structure decisions | provider source only |
| `schemas/`, `scripts/`, `tests/`, `mcp/` | contracts, checks, fixtures, capability registry | provider source only until explicitly deployed |
| `artifacts/`, `.github/workflows/` | audits/evals and CI | provider source only |
| `.codex/`, status, validation records | local/runtime state | never deploy |

Do not deploy source `.agents/runtime/`, `.codex/config.toml`,
`.codex/environments/environment.toml`, source memory rows, decisions, status,
or validation history by default.

## V2 Structure Rule

V2 structure changes must preserve mirror pairs and deployment rules until drift
checks are updated. Large moves of runbooks, templates, decisions, or memory docs
belong in dedicated changes, not mixed with validation, MCP, or CI work.

The `v2.1.0` enterprise dispatch layer is an optional overlay. Simple answer,
scoped edit, deploy, and release tasks still use the minimal route from
`docs/agents/ai-runtime.yaml` and should not load the organization files unless
the task is about departments, employees, delegation, or model binding.
