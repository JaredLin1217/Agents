# Skill Authoring

Use before creating or updating any project-local `SKILL.md`.

1. Confirm the workflow is repeatable and not better as `AGENTS.md`, memory, decision, runbook, or policy-pack rule.
2. Create skills only under `.agents/skills/<skill-name>/`.
3. Keep `SKILL.md` concise and procedural.
4. Put long explanations in `docs/agents/` or `docs/decisions/`.
5. Include `agents/openai.yaml` with required metadata.
6. Do not create project-specific skills in global Codex skill folders.

Key references:

- Skill policy: `docs/agents/workflows.yaml`
- Skill metadata schema: `docs/agents/schemas.yaml`
