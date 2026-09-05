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
- Replace simulated accuracy and synthetic scores with offline regression receipts
  and a real GPT-6 A/B evaluation protocol. Acceptance depends on measured results.
- Preflight model-host access before evaluation, retain failed diagnostics, and
  independently verify complete deployment and rollback in separate target fixtures.
- Support deep Git file paths without changing persistent user configuration.
- Remove fixed response decorations and retain natural user-language communication.
- Configure only this project's ignored local host settings for GPT-6/xhigh;
  do not distribute model settings or enable shared native memory.

Previous releases are preserved in Git at the immutable baseline recorded in
`docs/evidence/baseline.json`. This release has no legacy runtime compatibility.
