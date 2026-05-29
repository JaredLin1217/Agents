# Session Handoff

Use when work may continue across sessions, windows, employees, or app restarts.

1. Inspect `git status -sb --ignored --untracked-files=all`.
2. If active employees may exist, inspect the derived temp handoff cache.
3. Recover status from current git state, runtime handles, employee final reports, and remaining temp events.
4. If recovery is incomplete, mark state `unknown` instead of guessing.
5. Do not write shared status unless controller lease state is clear.

Key references:

- Handoff workflow: `docs/agents/workflows.yaml`
- Status/event/lease schemas: `docs/agents/schemas.yaml`
