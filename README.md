# Jared's AI Team

Agents **4.0.0** provides project rules, verifiable knowledge, recoverable task
state and deployment ownership for Codex engineering work. `agents.json` is the
version source. It is a file-based workflow, with no background memory service or
API model layer. GPT-6.1 Sol informs this revision; it is not forced on Consumers.

## Start

Read `AGENTS.md`; load specialized skills when needed. PowerShell 7 and Git are
required; ripgrep is optional. Routine work uses ordinary native tools.

```powershell
pwsh -NoProfile -File scripts/validate.ps1 -Scope Provider -Profile Changed
pwsh -NoProfile -File scripts/validate.ps1 -Scope Provider -Profile Checkpoint -Json
# Publication additionally requires current committed-source evidence.
pwsh -NoProfile -File scripts/validate.ps1 -Scope Provider -Profile Checkpoint -RequireReleaseReady
```

Reports persist before output and expose `receipt_path`, individual check states
and `release_ready`. A source checkpoint can pass with release evidence marked
`needs_review`; publication then fails RequireReleaseReady. There are no synthetic
quality scores or measured model task/token-saving claims.

## Three stores

| Store | Purpose | Contract |
|---|---|---|
| Versioned rules and skills | Mandatory conventions and specialized workflows | User scope and native instruction priority |
| `docs/memory/entries` | Reviewed facts, decisions and lessons | Immutable records, source checks, explicit retirement |
| `.agents/runtime` | Unfinished tasks and disposable artifacts | Registered runs, state and persistent tracking ledger |

Knowledge supports multiple queries, modules, tags and file locations. Verified
reusable nonsensitive findings are automatically promoted by the project-memory
workflow. Assumptions remain local. Native Codex memories assist recall; durable
knowledge always has explicit project files. Memory never grants permission.

Task saves use expected revision numbers and retain goal/acceptance history,
Git/index/file snapshots, receipt references and completed external actions.
Resume inspects real state and never replays an action. Multiple active tasks
require selection. Optional SessionStart/PreCompact/Stop hook templates use native
JSON and trust review; the same explicit commands work without hooks.

## Disposable artifacts

Agents payloads live in `.agents/runtime/runs/<run-id>`, pointers and locks in
`state`, and provenance/deletion history in `ledger`. Completed scratch/packages
expire after 7 days, receipts/diagnostics after 30, and tasks after 90. Active work,
unresolved failures and rollback dependencies stay protected. Cleanup previews
and rechecks ownership, hashes, links, dependencies and locks; unknown files stop
cleanup. Git, native Codex state and arbitrary external caches are outside this
contract. Ledger metadata survives payload deletion.

Both deployment layouts remain supported. Only catalogued assets are managed;
Consumer business files, knowledge, configuration and README remain user-owned.
This release changes Agents and tooling only; external projects need a separately
authorized upgrade. See the [operator guide](docs/runbooks/agents-operator-guide.md),
[v4 migration guide](docs/v4-upgrade.md), and [review](docs/reviews/agents-4.0-review.md).

## Evidence boundaries

The Checkpoint covers local offline contracts and disposable deployment targets.
Official evidence is generated after source commits, then verified and committed
separately. The declared v4 evidence path may be absent while editing; that is
explicitly not release-ready. No finite suite guarantees future correctness,
perfect recall, external project compatibility or enforced operating-system isolation.

Copyright 2026 Yu-Jie, Lin. Apache-2.0; see LICENSE and NOTICE. Provided AS IS.
