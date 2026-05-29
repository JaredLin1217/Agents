# Project File Structure

This template stores Agents operating rules inside the target repository. Canonical rules are compact AI-readable files under `docs/agents/`.

## Navigation

- `AGENTS.md`: compact every-session router and hard guardrails.
- `.agents/skills/project-isolation-workflow/SKILL.md`: project-local task router.
- `docs/agents/*.yaml`: canonical policy pack.
- `docs/runbooks/*.md`: short route files for humans and agents.
- `docs/templates/agents/`: source-neutral deployment starter bundle, copied by default for recursive deployability.

## Intended Layout

```text
.
|-- AGENTS.md
|-- .gitignore
|-- .agents/
|   `-- skills/project-isolation-workflow/
|       |-- SKILL.md
|       `-- agents/openai.yaml
`-- docs/
    |-- agents/
    |-- memory/
    |-- runbooks/
    `-- templates/agents/
```

## Directory Rules

- `.agents/skills/` contains project-local skills only.
- `docs/agents/` is the canonical compact policy pack.
- `docs/decisions/` is optional and target-owned.
- `docs/memory/` contains verified target-local lessons.
- `docs/runbooks/` contains short routers to the policy pack.
- `docs/templates/agents/` is copied by default. If a target removes it, also adapt rules and checks that reference the template bundle.
- Live multi-agent status belongs in `%TEMP%/codex-agent-status/<project-id>/`.
- Do not copy live status, source memory rows, source decisions, source Codex App config, or source local environment state by default.
