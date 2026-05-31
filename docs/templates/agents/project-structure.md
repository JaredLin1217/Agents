# Target Repo Structure

Agents rules and executable governance files live inside the target repo.

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
| `.agents/runtime/` | Target-local runtime coordination | never deploy |
| `docs/agents/*.yaml` | Canonical policy pack | deploy |
| `docs/runbooks/*.md` | Task entry points | mode-based deploy |
| `docs/templates/agents/` | Optional redeploy bundle | `template_provider_mode` only |
| `docs/memory/`, `docs/decisions/` | Target-local knowledge | target-owned |
| `docs/agents/decisions/` | Policy-pack structure decisions | target-owned unless explicitly deployed |
| `schemas/` | Machine-readable policy contracts | deploy only when enabled by target mode |
| `scripts/` | Local validation and maintenance commands | deploy only when enabled by target mode |
| `tests/` | Fixtures and automated validation tests | deploy only when enabled by target mode |
| `mcp/` | MCP capability registry and boundaries | deploy only when enabled by target mode |
| `artifacts/` | Trace, eval, and audit artifact boundary | runtime outputs ignored unless promoted |
| `.github/workflows/` | CI delivery lane | deploy only when enabled by target mode |
| `.codex/`, status, validation records | Local runtime state | never deploy |

- `AGENTS.md`: every-session router.
- `.agents/skills/project-isolation-workflow/`: project-local skill.
- `.agents/runtime/`: ignored coordination ledger and runtime state.
- `docs/agents/*.yaml`: canonical policy pack.
- `docs/runbooks/*.md`: short entry points.
- `docs/memory/`: target-local lessons.
- `docs/templates/agents/`: optional template-provider bundle for redeployment.
- `schemas/`: contracts for canonical YAML and future validation gates.
- `scripts/`: local executable checks and maintenance commands.
- `tests/`: fixtures and automated tests for policy-pack behavior.
- `mcp/`: target-level capability registry before MCP implementation.
- `artifacts/`: boundary for traces, evals, and audit outputs.
- `.github/workflows/`: CI workflows for stable local validation gates.

Target memory, decisions, agent ledger, status, Codex App config, local environment state, and validation history stay target-owned.

V2 structure changes should preserve existing mirror pairs and deployment rules
until the corresponding drift checks are updated. Large moves of runbooks,
templates, decisions, or memory docs should be handled as dedicated changes.
