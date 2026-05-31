# Decision 0002: Slimline Policy Pack

## Decision

Keep `AGENTS.md` and project-local skills compact. Store repeatable detailed behavior in `docs/agents/*.yaml`.

## Reason

Every-session context should stay small, while deployment, verification, memory, and multi-agent rules still need explicit contracts.

## Consequences

- `AGENTS.md` is a router and hard-guardrail file.
- `docs/agents/*.yaml` is the canonical Agents governance rules.
- Runbooks stay short and point to the Agents governance rules.
- Deployable templates mirror reusable rules but exclude source-project state.
