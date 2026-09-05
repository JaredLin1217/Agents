# Changelog

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
- Configure only this project's ignored local host settings for GPT-6/xhigh;
  do not distribute model settings or enable shared native memory.

Previous implementations and results remain in Git history, not runtime
compatibility code or mandatory validation dependencies.
