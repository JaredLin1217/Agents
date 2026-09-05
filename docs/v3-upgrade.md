# v3 Upgrade

v3 replaces the previous workflow architecture rather than adding compatibility.
Git commit `5e1643410233858ed70e4567beb01468fe0c2dc8` preserves the final v2.9.1
baseline, old schemas, runtime evidence and migration reference materials.

Removed: department and leader hierarchies, model tier routing, duplicated YAML
routes, provider adapters, chat envelopes, fixed reply decorations, runtime cleanup
against live host databases, generated public update commits and composite scoring.
The replacement is native skills plus small JSON-backed knowledge, checkpoints,
explicit file ownership and one validation registry. Tests, not agent self-ratings,
establish the stated outcomes.

The main project's ignored Codex configuration selects `gpt-6-astra` with `xhigh`.
The previous 64k compaction threshold is retained as a controlled variable, not
presented as a model context-window limit. Global and downstream settings are not
changed. Native memory injection and generation are disabled locally to prevent
cross-project knowledge sharing; versioned project knowledge remains available.
Restart/new sessions are required for host settings to take effect.

## Existing Installations
Do not force the new deployer over an unowned v2 installation. Old deployment
reports did not contain original content hashes, so their file names alone cannot
prove that current target files are unmodified. Before an authorized downstream
migration, reconstruct ownership from the exact original Provider commit and layout,
compare original bytes to the target, and review every retained or removed path.
A reviewed v3 managed manifest may record those verified originals; unchanged old
owned paths are removed by the next preview. Conflicts require deliberate review,
not an overwrite flag. This is a one-time operator migration, not old runtime support.

Preserve target knowledge, product docs, local configuration and historical data.
This release's implementation and regression targets are local disposable projects;
no production downstream rollout is implied.

## Evaluation
The former resolver selection tests were not model-task A/B tests. v3 separates
pointer/parse unit coverage from actual CLI runs. The model benchmark fixes 12
tasks, two groups and three repetitions before running; failures and missing
metrics remain visible. Same model and effort, fresh task roots and no shared
answers/memory are required. See `tests/evaluation/README.md` and the generated
evaluation report for actual completion, safety and efficiency gates.

Current release status is a candidate, not model-accepted. See
`docs/evidence/v3-evaluation-status.json` for all four real pilot samples and the
separate environment preflight. The Windows backend selection now permits ordinary
file operations, but protected runtime writes were denied; local commit was not
attempted after that denial. Engineering checkpoint success alone does not authorize
a v3 release tag or claim the planned token savings. The finalized candidate still
needs the complete frozen 72-task run in an authorized working CLI environment.

The candidate fixture without task prompts and grading entry points also passed
its offline checkpoint, complete installation checks and restoration in a separate
disposable target. This validates the evaluation setup, not model task outcomes.
