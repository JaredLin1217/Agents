# Multi-Agent Workflow

Use only after explicit hire/spawn/delegate/parallel-agent request or clear equivalent.

## Fast Path

1. Run one controller status check only when current repo state or edits matter.
2. Create one reusable brief per role type from `explorer_brief_assignment` or the full worker assignment.
3. Fill the runtime's current maximum active slots, keep the rest queued, and refill immediately when one employee completes.
4. Do not re-read this runbook or every canonical YAML file for each employee.
5. Append recovery-sensitive lifecycle events to `.agents/runtime/agent-ledger.jsonl`.
6. Close completed employees after recording the final report; final report is the completion notification.
7. If sidebar/history cleanup is authorized, clean Codex App DB records for the exact closed runtime ids and record a `history_cleanup` ledger event.

## Close And Sidebar Cleanup

- Runtime close comes first. Do not use DB deletion as a substitute for `close_agent`.
- Cleanup is authorized by the user close request for the exact runtime ids closed in that request; standalone cleanup requires explicit authorization.
- Treat `%USERPROFILE%/.codex/state_*.sqlite` as external runtime state; report DB reads/writes as XR/XW.
- Match only rows for the current repo cwd after normalizing Windows `\\?\` prefixes and path separators.
- Delete only matching subagent `thread_dynamic_tools`, `thread_spawn_edges`, and `threads` rows.
- Optional orphan edge cleanup is allowed only when both endpoints are missing and cleanup was requested.
- Never delete parent/controller threads or unrelated project history.

## Scoring Batches

- Default to 3 read-only scorers; expand to 5 only if score spread exceeds 10 points or top issues conflict.
- Hard cap at 7 for high-risk disagreement, or 10 with explicit user approval. Larger batches require explicit user request.
- Before launching more than 5 scorers, state the unresolved disagreement or coverage gap; otherwise aggregate and stop.
- Aggregate median-first, also report mean/range/confidence.
- Dedupe findings by scope, root cause, and proposed fix. Count duplicates as confidence.
- Ignore repeated identical final reports after the first recorded report hash.
- After the hard cap, report disagreement instead of spawning more scorers.

## Safety Rules

- Use read-only explorers for scoring, review, or investigation.
- Use workers only with exclusive normalized write scope.
- Poll/close before controller edits overlap active worker scope.
- Use the project-local ledger for detached, long-lived, concurrent, write-capable, or recovery-sensitive employees.
- Use temp roster only as external fallback; report temp access as XR/XW.
- Never stage volatile ledger, roster, event, lease, or filled validation files.

References: `docs/agents/workflows.yaml`, `docs/agents/schemas.yaml`, `docs/agents/verify.yaml`.
