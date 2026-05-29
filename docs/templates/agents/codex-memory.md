# Codex Memory Layout

Canonical policy: `docs/agents/workflows.yaml`.

Use repo-local memory only unless the user explicitly approves global Memory.

- Every-session rules: `AGENTS.md`
- Workflow rules: `docs/agents/*.yaml`
- Verified reusable lessons: `docs/memory/index.md` plus optional `docs/memory/entries/`
- Decisions: `docs/decisions/`
- Repeatable procedures: `docs/runbooks/` or `.agents/skills/`

Add memory only when the lesson is verified, project-specific, and likely to recur. Use the `memory_entry` schema in `docs/agents/schemas.yaml`.
