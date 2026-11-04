# Agents Governance

Agents **5.0.0** is a local-first project governance package for Codex work. It
keeps project rules explicit, knowledge verifiable, unfinished tasks recoverable
and deployment changes owned. `agents.json` is the version source.

The release provides a cross-platform PowerShell 7.4+ CLI, root and
dot-agents layouts, a one-way v4 migration, immutable project memory, runtime
artifact lifecycle management and a Codex plugin package. It does not provide a
hosted multi-tenant service or telemetry.

## Start

Use the unified command surface:

```powershell
pwsh -NoProfile -File scripts/agents.ps1 plan -Json
pwsh -NoProfile -File scripts/agents.ps1 validate changed -Json
pwsh -NoProfile -File scripts/agents.ps1 doctor -Json
pwsh -NoProfile -File scripts/agents.ps1 runtime list -Json
```

Use `validate checkpoint` once at the delivery boundary. Publication also
requires committed v5 evidence and `-RequireReleaseReady`.

## Three stores

| Store | Purpose | Contract |
|---|---|---|
| Versioned rules and skills | Required project conventions | Native instruction priority and current user authorization |
| `docs/memory/entries` | Verified facts, decisions and lessons | Immutable records, source hashes and explicit retirement |
| `.agents/runtime` | Tasks, receipts and disposable artifacts | Registered runs, state, ledger and guarded cleanup |

Native Codex memory is an optional recall layer. It never replaces checked-in
rules, grants permission or authorizes an external action.

## Distribution

`plugins/agents-governance` is the primary Codex distribution. It contains the
portable `plugin.json`, Codex compatibility manifest, onboarding and governance
skills. Lifecycle hooks remain a separate opt-in template and require native
trust review. `scripts/package-plugin.ps1` creates a deterministic ZIP and
SHA-256 record under registered runtime storage.

## Migration and deployment

Existing v4 Consumers require an explicit dry-run and apply through
`scripts/migrate-v4-to-v5.ps1`. The command backs up managed files, verifies
hashes and preserves business files. Deployment uses a dry-run plan and exact
digest; rollback validates original bytes before restoring.

## Evidence boundary

Receipts distinguish passed, failed, needs_review and not_applicable. Offline
checks do not measure model accuracy or guarantee future recall. Git metadata,
Codex native state and arbitrary external caches are outside the runtime
contract. See the [operator guide](docs/runbooks/agents-operator-guide.md),
[v5 review](docs/reviews/agents-5.0-review-2026-11-05.md) and
[history](docs/history/agents-evolution.md).

Copyright 2026 Yu-Jie, Lin. Apache-2.0; see `LICENSE` and `NOTICE`.
