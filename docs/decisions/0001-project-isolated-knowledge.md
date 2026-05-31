# Decision 0001: Project-Isolated Knowledge

## Decision

Keep Codex project knowledge in this repo. Do not use global Codex Memory for normal work.

## Rules

- `AGENTS.md`: every-session router.
- `docs/agents/*.yaml`: canonical compact Agents governance rules.
- `docs/memory/index.md` and `docs/memory/entries/`: verified reusable project lessons.
- `docs/runbooks/` and `.agents/skills/`: repeatable workflows.
- `docs/decisions/`: durable decisions.
- Use global/system capability only when explicitly requested or higher-priority runtime rules require it; report it.
- Project-external filesystem access requires exact user authorization, except the approved temp handoff cache.
- Closeout must include the isolation line and verified claim scope.

## Consequences

- New sessions recover context from repo files.
- Deployments stay portable and auditable.
- This is repo-level behavior policy, not a runtime sandbox or hard blocker.
