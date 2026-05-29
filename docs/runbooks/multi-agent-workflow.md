# Multi-Agent Workflow

Use when the user asks to hire, spawn, coordinate, poll, close, or review employees.

1. Read `AGENTS.md`.
2. Confirm the user explicitly requested employee, spawn, delegation, parallel-agent work, or a clear natural-language equivalent before launching runtime employees.
3. Treat goal continuation, broad optimization, quality audit, static validation, and self-scoring requests as non-launching unless they also explicitly request employee/delegation/parallel-agent work.
4. Choose mode before assignment: `session-managed`, `manual-detached`, or `cloud-or-automation`.
5. Prefer `manual-detached` for sidebar-visible, user-controllable, non-blocking, or longer-running local work.
6. Assign `explorer` for read-only work or `worker` for bounded edits.
7. Define and normalize exclusive owned write scope for every worker before launch.
8. Record the ownership matrix and conflict status when any worker exists or two employees are active.
9. Start from `docs/agent-assignment.template.md` and include assignment fields from `docs/agents/schemas.yaml`.
10. Create or update the exact derived temp roster when an employee may outlive controller context, run beside another employee, or edit files; report that temp cache access as project-external XR/XW.
11. Tell employees that final report is the completion notification.
12. Poll active employees at task boundaries before overlapping edits or final closeout.
13. Close employees by runtime id first; archive or history cleanup is separate and needs explicit authorization when it touches Codex internals.
14. Before claiming no remaining multi-agent runtime deductions, satisfy `docs/agents/verify.yaml` live employee validation and fill `docs/runtime-multi-agent-validation.template.md` or cite equivalent current evidence.
15. Controller reviews reports and diffs before integration.

Key references:

- Workflow details: `docs/agents/workflows.yaml`
- Assignment/report schemas: `docs/agents/schemas.yaml`
- No-deduction and multi-worker gates: `docs/agents/verify.yaml`
