# Multi-Agent Workflow

Use only after explicit hire/spawn/delegate/parallel-agent request or clear equivalent.

## Fast Path

1. Run one controller status check only when current repo state or edits matter.
2. Create one reusable brief per role type from `explorer_brief_assignment` or the full worker assignment.
3. Fill the runtime's current maximum active slots, keep the rest queued, and refill immediately when one employee completes.
4. Do not re-read this runbook or every canonical YAML file for each employee.
5. Close completed employees after recording the final report; final report is the completion notification.

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
- Use the temp roster when two or more employees are active, work may outlive context, writes occur, or later recovery matters.
- Report temp roster access as XR/XW; never stage volatile roster, event, lease, or filled validation files.

References: `docs/agents/workflows.yaml`, `docs/agents/schemas.yaml`, `docs/agents/verify.yaml`.
