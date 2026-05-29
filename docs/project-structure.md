# Project Structure

Repo-local Agents rules live here; global Codex Memory is not the normal knowledge store.

## Map

- `AGENTS.md`: every-session router and guardrails.
- `.agents/skills/project-isolation-workflow/`: project-local skill.
- `docs/agents/*.yaml`: canonical policy pack.
- `docs/runbooks/*.md`: short entry points.
- `docs/templates/agents/`: source-neutral deploy bundle.
- `docs/memory/`: verified project lessons.
- `docs/decisions/`: source-project decisions.

## Rules

- `.codex/config.toml` is source-project local and not deployable by default.
- `.codex/environments/environment.toml` is ignored local runtime state.
- `.codex/environments/environment.template.toml` is reference-only.
- Do not deploy source memory rows, decisions, status, or environment state by default.
- Live multi-agent handoff state belongs in `%TEMP%/codex-agent-status/<project-id>/`.
