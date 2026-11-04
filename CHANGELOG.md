# Changelog

## 5.0.0 - Commercial Governance Package

- Move the active contract to `agents-project/v5` with an explicit v4 migration;
  historical schemas and rules no longer load in the active deployment surface.
- Add the unified cross-platform PowerShell CLI for planning, validation, memory,
  tasks, runtime, deployment, diagnostics and packaging.
- Add portable Codex plugin manifests, onboarding, deterministic ZIP packaging and
  SHA-256 output. Lifecycle hooks remain a separate trusted opt-in template.
- Refresh official OpenAI source hashes and boundaries for GPT-6.1 Sol, AGENTS.md,
  skills, memories, hooks and plugins.
- Keep local-only execution and zero telemetry while adding platform support and
  staged validation so full suites run at delivery boundaries.
- Add one-way v4 migration with dry-run digest, managed-file backup and rollback.

## 4.0.0 - Verified Knowledge and Runtime Lifecycle

- Review GPT-6.1 Sol and current native rules, skills, memories and hooks sources;
  remove fixed host settings, worker counts and arbitrary byte limits.
- Add v4 immutable knowledge provenance, multi-query retrieval, explicit
  migration/retraction, freshness and permanent retirement.
- Add versioned task requirements, acceptance criteria, Git/index/file state,
  receipt dependencies, completed external actions and expected-revision saves.
- Register generated payloads under runtime runs with 7/30/90 retention, pins,
  guarded cleanup previews, staging journals and persistent deletion tracking.
- Deliver advisory native JSON hooks templates and manual equivalents.
- Persist validation receipts before output; distinguish source validation from
  committed-source publication readiness and enforce RequireReleaseReady.
- Preserve both deployment layouts, ownership, idempotence and verified rollback;
  leave external Consumer upgrades and hook activation to separate operations.

## 3.0.0 - Native Workflow Rewrite

- Replace mandatory routing, hierarchy, envelopes, and provider declarations with
  concise native rules and two progressively loaded skills.
- Use optional pointer-first context discovery without intent classification,
  fixed file-count completeness claims, or whole-repository indexing.
- Store reviewed knowledge as source-checked JSON and incomplete work as ignored
  checkpoints; suspend stale/conflicted knowledge and verify state on recovery.
- Unify Changed/Checkpoint validation and separate Provider/Consumer scopes.
- Deploy explicit hashed ownership maps with conflict detection, approved preview
  digests, rollback journals, and no source-code path rewriting.
- Keep current-version offline regression receipts instead of synthetic scores.
  Verify deployment, rollback, memory and recovery in disposable local targets.
- Retire old-version comparison runners, model-host probes, historical report
  copies and relative baseline gates. Validation no longer launches model tasks;
  prior incomplete runs do not establish task accuracy or token savings.
- Support deep Git file paths without changing persistent user configuration.
- Remove fixed response decorations and retain natural user-language communication.
- Historical documentation asserted local GPT-6/xhigh settings; the 2026-10-08
  checkout did not contain that configuration. v4 corrects this claim.

Previous implementations and results remain in Git history, not runtime
compatibility code or mandatory validation dependencies.
