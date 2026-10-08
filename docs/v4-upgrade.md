# Agents 4.0 migration

Scope is this Provider and its deployable tooling. Existing external Consumers
are not automatically upgraded. Version is 4.0.0 in agents.json. Project,
knowledge, task, validation and runtime contracts advance; managed/deployment and
source-registry schemas remain v3 because their structures are unchanged. Legacy
knowledge/task schemas are embedded in the current readers; historical formal
v5 release evidence remains readable but cannot establish a v4 release gate.

## Rules and settings

Root rules retain authorized goal, existing-work preservation, evidence, ownership
and recovery boundaries. Fixed models, compaction thresholds, native-memory bans,
worker counts, exploration mandates and hard byte limits are removed. API guidance
for GPT-6.1 Sol is documented in the review, never imposed on the Codex host.
No `.codex/config.toml` exists in the inspected baseline; earlier documentation
asserting local settings is corrected. Global settings and native memory are untouched.

## Knowledge and tasks

Keep v3 entry files. Recall rechecks them; new findings use v4. Reinspect original
sources and conclusions, create a reviewed v4 proposal with supersedes, then run
Migrate. M002 replaces the verified M001 language/intent lesson without changing
its old ID/file. Do not translate old source hashes into new evidence blindly.
Retraction is another immutable record. Active knowledge needs durable evidence;
expired temporary receipts cannot be its sole source.

Resume can inspect v3 task files under runtime/tasks, but requires reinspection.
Explicit task Migrate uses a reviewed task-input and ExpectedRevision 0; it keeps
the exact legacy bytes/hash in the registered task archive and creates a v4 run,
immutable revision and pointer. It removes only the proven old copy after saving
that pointer, so legacy state does not remain an untracked cleanup blocker. Reconfirm
the latest user requirements and external operations. Multiple active tasks are
listed. Save now requires acceptance criteria, knowledge/receipt associations and
external-action history, plus the expected current revision. Complete starts 90 days.

## Runtime

Inventory legacy runtime before cleanup. Manifest-proven legacy packages may be
migrated with Reconcile -InputPath <legacy package> -ExpectedDigest <tree digest>
-Reason <reviewed reason>. Every listed file and hash must match, with no unknown
children or links. New copies are registered before old verified payloads are
removed. Unknown content remains review-needed. Legacy deployment journals remain
recoverable and pinned until explicit retirement; do not delete their old locks
without checking the owner and transaction.

All new payloads use runtime/runs; state and ledger are distinct. Active tasks,
failures and rollback dependencies are pinned. Cleanup always uses an exact
preview and records deletion. Do not clear old directories to make a validation
report look clean. Fixed clock tests verify boundaries; operational checks use UTC now.

## Deployment and hooks

Update with an authorized existing target's ownership manifest, the unchanged
layout and an inspected preview digest. New runtime helpers, schemas, the third
skill and templates are catalogued. Ownership conflicts stop before writes; both
layout regression suites exercise complete rollback, including damaged backups.
Hook templates are delivered under docs/templates and require deliberate native
trust activation. Tools never write `.codex/hooks.json` or global Codex settings.

## Delivery versus publication

The Provider Checkpoint saves the implementation receipt and reports review gaps.
No v4 release evidence is fabricated for an uncommitted worktree. Commit the source,
capture and verify official evidence, commit only that declared evidence file,
then require release readiness before publication. This implementation does not
promise perfect future conversation recall or universally correct model behavior.
