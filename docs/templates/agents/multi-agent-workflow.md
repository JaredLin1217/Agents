# Multi-Agent Workflow

Use when the user asks to hire, spawn, coordinate, poll, close, or review employees.

1. Read `AGENTS.md`.
2. Choose mode before assignment: `session-managed`, `manual-detached`, or `cloud-or-automation`.
3. Prefer `manual-detached` for sidebar-visible, user-controllable, non-blocking, or longer-running local work.
4. Assign `explorer` for read-only work or `worker` for bounded edits.
5. Define exclusive owned write scope for every worker before launch.
6. Include assignment fields from `docs/agents/schemas.yaml`.
7. Tell employees that final report is the completion notification.
8. Use `%TEMP%/codex-agent-status/<project-id>/` only when handoff persistence is needed.
9. Poll active employees at task boundaries before overlapping edits or final closeout.
10. Controller reviews reports and diffs before integration.

Key references:

- Workflow details: `docs/agents/workflows.yaml`
- Assignment/report schemas: `docs/agents/schemas.yaml`
- No-deduction and multi-worker gates: `docs/agents/verify.yaml`
