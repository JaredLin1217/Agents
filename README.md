# Jared's AI Team

Project-local operating rules, recoverable knowledge, and safe deployment for
Codex engineering work. Version **3.0.0**, defined in `agents.json`.
Status: engineering candidate; formal model acceptance is blocked. The
[evaluation status](docs/evidence/v3-evaluation-status.json) includes every pilot
sample and the remaining release gate. No token-saving claim is established.

## Start Here

Read `AGENTS.md`. Use ordinary Codex tools for ordinary work; there is no required
route resolver, department hierarchy, response envelope, or fixed chat footer.
Skills load specialized guidance only when needed.

```powershell
# Routine changes; add -Path for a deliberately narrowed claim.
.\scripts\validate.ps1 -Scope Provider -Profile Changed
# Before commit, push, deployment, or release.
.\scripts\validate.ps1 -Scope Provider -Profile Checkpoint
# Optional discovery, not a complete impact analysis.
.\scripts\resolve-agent-context.ps1 -Path scripts/project-memory.ps1 -BudgetBytes 8192
```

PowerShell 7, Git, and optionally ripgrep are required. No graph database,
custom YAML parser, background service, or API-specific model layer is installed.

## What Is Durable

- `AGENTS.md` and `.agents/skills/`: versioned behavior and specialized guidance.
- `docs/memory/entries/*.json`: reviewed facts, decisions, and reusable lessons.
  Source hashes are checked before recall; stale/conflicted facts are suppressed.
- `.agents/runtime/`: ignored task checkpoints, generated indexes, receipts,
  packages, and disposable test state. Not deployable project knowledge.
- `docs/agents/deployment.json`: explicit source-to-destination ownership.
- `docs/agents/sources.json`: dated official sources and capability boundaries.
- `tests/`: deterministic regression tests and separately controlled model tasks.

Consumers receive only the catalogued rules, skills, schemas, and light helpers.
Their business code, knowledge, product documentation, local configuration, and
history are not managed by the provider. Both layouts remain supported.

## Evidence, Not Scores

The checkpoint reports individual check receipts, not a synthetic quality score.
Offline regression success does not establish model task accuracy or Token savings.
The model benchmark uses independent fixed acceptance tests and records failures
and actual CLI usage. See `tests/evaluation/README.md` for protocol and status.
No finite test suite guarantees future correctness or that a model never forgets.

Use the [operator guide](docs/runbooks/agents-operator-guide.md) for deployment,
rollback, memory, recovery, and source/evidence commits. See
[v3 upgrade notes](docs/v3-upgrade.md) for removal and migration boundaries.
Historical implementations and changelogs remain in Git, not compatibility code.

## License

Copyright 2026 Yu-Jie, Lin. Apache-2.0; see `LICENSE` and `NOTICE`.
Provided AS IS, without warranties or guarantees of fitness for a target system.
