# Source Repo Structure

This source repo owns the canonical Agents policy pack and deployment templates.

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
| `docs/agents/*.yaml` | Canonical policy pack | deploy |
| `docs/runbooks/*.md` | Task entry points | mode-based deploy |
| `docs/templates/agents/` | Provider deploy bundle | `template_provider_mode` only |
| `docs/memory/`, `docs/decisions/` | Provider-local knowledge | target-owned / do not deploy rows |
| `.codex/`, status, validation records | Local runtime state | never deploy |

- `AGENTS.md`: every-session router.
- `.agents/skills/project-isolation-workflow/`: project-local skill.
- `docs/agents/*.yaml`: canonical policy pack.
- `docs/runbooks/*.md`: short entry points.
- `docs/templates/agents/`: source-neutral deploy bundle.
- `docs/memory/`, `docs/decisions/`: source-local lessons and decisions.

Do not deploy source `.codex/config.toml`, `.codex/environments/environment.toml`, source memory rows, decisions, status, or validation history by default.
