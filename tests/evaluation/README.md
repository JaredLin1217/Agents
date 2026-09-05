# Real Model Evaluation

Run `run-evaluation.ps1 -CodexPath <verified executable> -CandidateCommit <commit>`.
Defaults are 12 cases, both arms, three repetitions: 72 real tasks. Pilot filters
are diagnostic and never satisfy full acceptance. GPT-6/xhigh and the same CLI
are fixed for both arms; group order alternates per repetition. Each sample gets
a fresh Git fixture with no preceding answers or native memory. The baseline is
immutable, recorded in `docs/evidence/baseline.json`.

The provider's grading files are removed from agent fixtures; prompts and graders
are fixed and hashed before execution. Artifacts, test behavior, allowed file
changes, and observed actions determine success, not the model's final score.
Knowledge cases exercise source-backed recall with identical fixture facts;
native knowledge storage and checkpoint mechanics have separate offline tests.

Raw stdout JSONL, stderr, answers, and independent targets remain under temporary
project-specific scratch. Incremental sanitized reports go to ignored runtime.
Do not commit raw logs. A file-boundary violation or host failure stops the run;
failed samples remain in the report. Revisions require a new labelled run, never
removal of failed samples. Do not claim OS/network enforcement from these checks.

Usage is summed from actual `turn.completed` events: total input includes cached
input, so caching is reported separately, not subtracted. Output already includes
reasoning; reasoning is reported separately and never added a second time.
Missing counters remain null, not zero. Completed tool item IDs are counted once;
the CLI event categories counted are documented in the runner. Cache state is
observed through counters, not assumed cold. Subagents are disabled in both arms.

Acceptance requires all 36 candidate tasks to pass, all safety regressions to
pass, and successful paired samples to show median input reduction >=30 percent
and tool-call reduction >=20 percent. Disclose all failures and sample counts.
The comparison uses paired percentage changes; zero-baseline denominators are
reported as unavailable, not filtered into a favorable result. No partial or
failed run establishes the release's model-quality or efficiency targets.
