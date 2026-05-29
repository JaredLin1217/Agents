# Session Handoff

Use when work may continue across sessions, windows, employees, or app restarts.
Trigger on session/window/app restart, employee recovery, or uncertain continuation state.

1. Inspect git state.
2. If employees may exist, inspect the exact temp handoff cache and report XR.
3. Treat temp roster as advisory; recover from git, runtime handles, final reports, temp events, and controller lease.
4. If recovery is incomplete, mark state `unknown`; do not close by nickname alone.
5. Report recovered sources, unknowns, and XR for temp cache access.

References: `docs/agents/workflows.yaml`, `docs/agents/schemas.yaml`.
