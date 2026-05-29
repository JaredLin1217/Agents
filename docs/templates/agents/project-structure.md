# Target Repo Structure

Agents rules live inside the target repo.

## Read Order

1. `AGENTS.md`
2. `docs/agents/workflows.yaml`
3. `docs/agents/policy.yaml`
4. `docs/agents/verify.yaml`
5. `docs/agents/schemas.yaml` only for assignments, reports, status, or templates
6. `docs/agents/deploy.yaml` only for authorized redeployment

## Role Matrix

| Area | Role | Deploy policy |
|---|---|---|
| `AGENTS.md` | Target router | deploy |
| `.agents/skills/project-isolation-workflow/` | Target-local skill | deploy |
| `docs/agents/*.yaml` | Canonical policy pack | deploy |
| `docs/runbooks/*.md` | Task entry points | mode-based deploy |
| `docs/templates/agents/` | Optional redeploy bundle | `template_provider_mode` only |
| `docs/memory/`, `docs/decisions/` | Target-local knowledge | target-owned |
| `.agents/runtime/`, `.codex/`, status, validation records | Local runtime state | never deploy |

- `AGENTS.md`: every-session router.
- `.agents/skills/project-isolation-workflow/`: project-local skill.
- `docs/agents/*.yaml`: canonical policy pack.
- `docs/runbooks/*.md`: short entry points.
- `docs/memory/`: target-local lessons.
- `docs/templates/agents/`: optional template-provider bundle for redeployment.

Target memory, decisions, agent ledger, status, Codex App config, local environment state, and validation history stay target-owned.
