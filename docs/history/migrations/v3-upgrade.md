# v3 Upgrade

v3 uses native skills, optional context discovery, source-checked JSON knowledge,
task checkpoints and explicit deployment ownership. It has no mandatory routing
hierarchy, chat envelope, fixed reply decoration or runtime compatibility layer.
Previous implementations remain in Git history, not the current working tree.

## Historical Configuration Claims
This document describes the v3 migration. The checkout inspected on 2026-10-08
has no `.codex/config.toml`; earlier assertions of a local Astra model, 64k
compaction threshold and disabled native memory were unsupported by that checkout.
v4 removes those operating claims and leaves host settings user-controlled. See
`v4-upgrade.md` and the current operator guide.

## Existing Files
Deploy only into an explicitly authorized target. Existing file names do not prove
ownership. Review original hashes before adopting any existing rules into a managed
manifest; modified or unowned files stop writes. Preserve business code, product
documentation, local settings, project knowledge and historical data. There is no
overwrite or compatibility switch. Downstream deployment is a separate operation.

## Minimal Verification
Use `validate.ps1 -Scope Provider|Consumer -Profile Changed` while editing and
`-Profile Checkpoint` for handoff, commit or deployment. One registry checks syntax,
JSON contracts, ownership, knowledge and relevant source freshness. Provider adds
size measurements, core regression, the release package and source-bound evidence.
Consumer does not run Provider tests. Registered product tests remain project-owned.

The owner replaced model-comparison acceptance with current-version offline checks
on 2026-09-06. Comparison runners, host probes, old baselines and historical report
copies were removed. Incomplete comparison results are not reclassified as success;
no measured model-accuracy or token-saving claim is made.

Core regression retains both deployment layouts, Chinese and spaced paths, no-write
previews, complete rollback, ownership conflicts, damaged backups, memory retirement,
staleness, conflicts and task reinspection. The release collector runs this same
registry from clean committed source. Commit only the declared evidence file after
capture. These checks do not prove external deployment readiness or hard isolation.
