# Project File Structure

This repository stores Agents operating rules locally instead of using Codex global Memory. Canonical rules are compact AI-readable files under `docs/agents/`.

## Navigation

- `README.md`: short human orientation.
- `AGENTS.md`: compact every-session router and hard guardrails.
- `.agents/skills/project-isolation-workflow/SKILL.md`: project-local task router.
- `docs/agents/*.yaml`: canonical policy pack.
- `docs/runbooks/*.md`: short route files for humans and agents.
- `docs/templates/agents/`: source-neutral deployment starter bundle.

## Current Layout

```text
.
|-- AGENTS.md
|-- README.md
|-- .gitattributes
|-- .gitignore
|-- .codex/
|   |-- config.toml
|   `-- environments/
|       |-- environment.template.toml
|       `-- environment.toml
|-- .agents/
|   `-- skills/project-isolation-workflow/
|       |-- SKILL.md
|       `-- agents/openai.yaml
`-- docs/
    |-- agents/
    |-- runbooks/
    |-- templates/agents/
    |-- memory/
    `-- decisions/
```

## Directory Rules

- `.codex/config.toml` belongs only to this repository and is not deployable by default.
- `.codex/environments/environment.toml` is local runtime state and must stay ignored.
- `.codex/environments/environment.template.toml` is reference-only.
- `.agents/skills/` contains project-local skills only.
- `docs/agents/` is the canonical compact policy pack.
- `docs/decisions/` contains source-project decisions; copy only decisions a target explicitly adopts.
- `docs/memory/` contains verified project-local lessons; do not deploy source memory rows by default.
- `docs/templates/agents/` contains clean deployment starters and a source-neutral policy-pack copy.
- Live multi-agent status belongs in `%TEMP%/codex-agent-status/<project-id>/`.
