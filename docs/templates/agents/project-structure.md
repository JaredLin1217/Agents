# Project Structure

Agents rules live inside the target repo.

## Map

- `AGENTS.md`: every-session router.
- `.agents/skills/project-isolation-workflow/`: project-local skill.
- `docs/agents/*.yaml`: canonical policy pack.
- `docs/runbooks/*.md`: short entry points.
- `docs/templates/agents/`: deploy bundle, copied by default for recursive deployability.
- `docs/memory/`: target-local lessons.

## Rules

- Keep memory, decisions, status, Codex App config, local environment state, and validation history target-owned.
- If a target removes `docs/templates/agents/`, also adapt rules and checks that reference it.
- Live multi-agent handoff state belongs in `%TEMP%/codex-agent-status/<project-id>/`.
