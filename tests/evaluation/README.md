# Real Model Evaluation

Run `run-evaluation.ps1 -CodexPath <verified executable> -CandidateCommit <commit>`.
Defaults are 12 cases, both arms, three repetitions: 72 real tasks. Pilot filters
are diagnostic and never satisfy full acceptance. GPT-6/xhigh and the same CLI
are fixed for both arms; group order alternates per repetition. Each sample gets
a fresh Git fixture with no preceding answers or native memory. The baseline is
immutable, recorded in `docs/evidence/baseline.json`.
Both fixtures contain the same pre-evaluation v2.8 Git objects required by the
frozen baseline's regression checks. The host imports that exact historical commit
through local Git only, without configuring a remote or importing v3 history,
task answers, native memory or earlier sample state.

Each sample contains a Provider checkout and a separate sibling target: the v2
baseline refuses to deploy inside its own checkout. Only deployment/rollback calls
receive that exact target via `--add-dir`.
An explicitly authorized, invocation-only permission profile allows code, `.agents`
and Git writes in these disposable roots, keeps `.codex` read-only, and disables
command network access. It does not inherit writable system temp directories.
Launches outside the project-specific evaluation scratch or through linked roots
are rejected. Both targets start with an identical inert local environment file;
deployment must preserve it. Failed preflight remains blocking. Both arms use the same
topology. Reports use `workload/target/` as its stable logical path, not an absolute
machine-specific location.
Every call also receives a unique, explicitly authorized private validation temp
inside project-specific disposable scratch. `TEMP`, `TMP` and `TMPDIR` point there
only in the child process. No writable system-temp or parent-directory grant is
inherited. A raw harness manifest records the exact directory. Both arms keep
the validator's default temp selection; a temp nested inside the Provider breaks
the frozen baseline's self-deployment boundary. Short checkout/temp paths and
child-only `core.longpaths=true` support Windows Git without changing global Git
configuration. The parent environment is not changed.

Before any model call, full validation qualifies both frozen-source fixtures in
the actual command sandbox with this same temp topology and permissions. A source
or target mutation, failed validator or failed filesystem probe stops the run.
Qualification uses separate fixtures, never task answers or model-task receipts.
Run `test-environment.ps1 -CodexPath <executable> -CandidateCommit <commit>` for
this no-model diagnostic alone. It is overhead, not an acceptance sample.

The runner then checks actual file read/write, ignored runtime writes and a local
Git commit in a separate disposable fixture, using exactly the task host arguments.
Before any model call, a command-only sandbox probe checks runtime writes and
expected denial of writes to `.codex` and outside the fixture. These narrowly
defined negative tests are not agent task attempts or permission retries.
Run `test-host.ps1 -CodexPath <executable>` for the same diagnostic alone. A failed
preflight stops before allocating task samples; its real usage remains a separate
overhead record, never part of the 72-task acceptance count. Windows explicitly
selects the already provisioned `elevated` backend because `--ignore-user-config`
otherwise drops that setting. This does not install a sandbox or change host settings.
The runner never disables rules or changes global permissions. If the configured
sandbox refuses Git or runtime writes, use an appropriately authorized evaluation
environment; do not weaken the controls to manufacture passing results.
The profile uses the documented permission-profile interface, not legacy `-s`
settings or a full-access fallback: https://learn.chatgpt.com/docs/permissions.

Offline Git calls use invocation-local long-path support for deeply nested fixture
files. Keep repository working-directory paths below the Windows Git startup limit;
long-path file support does not remove that separate limitation.

Task prompts and independent grading files are removed from agent fixtures;
non-grading host/metrics helpers remain so Provider regression tests still work.
Prior evaluation reports, diagnostic status and host-only qualification entrypoints
are also removed. Frozen baseline metadata and offline release evidence remain
available to the required Provider checks; earlier task outcomes do not.
Prompts, graders and their imported helpers are fixed and hashed before execution.
Every task receives its acceptance criteria and allowed write set as explicit instructions; the same set
still drives independent post-run checks. Read-only tests are not hidden scope
constraints. The cross-module fixture starts with a failing integration check for
the requested new behavior (33), not the obsolete behavior (21). A command-only
fixture preflight checks all twelve cases with valid reference artifacts and
invalid mutants. Code tasks also require the application fix to pass the unchanged
visible test, and that test must reject the mutant. Diagnosis checks explicitly
include negative-quantity rejection. These host-only reference solutions never
enter model fixtures. The preflight tests the grader, not model task quality.
Corrected protocols start new runs; stopped reports remain
unchanged and never count toward the replacement run.
Artifacts, test behavior, allowed file
changes, and observed actions determine success, not the model's final score.
Knowledge cases exercise source-backed recall with identical fixture facts;
native knowledge storage and checkpoint mechanics have separate offline tests.
Recovery uses two separate ephemeral CLI sessions, a persisted checkpoint, and
an intervening invoice change. It is one task with both sessions' usage counted;
the deployment counter is explicitly a mock external action, not a real rollout.
Rollback also has two sessions. The harness verifies complete installed assets
after the first, then checks restoration against the original target snapshot.
Doing nothing cannot count as a successful rollback. Both sessions' usage counts.

Raw stdout JSONL, stderr, answers, and independent targets remain under temporary
project-specific scratch. Incremental sanitized reports go to ignored runtime.
Snapshots include ignored files and nested targets, excluding Git metadata and
the two explicitly allowed runtime scratch directories. Linked paths fail closed.
Do not commit raw logs. A file-boundary violation or host failure stops the run;
failed samples remain in the report. Revisions require a new labelled run, never
removal of failed samples. Do not claim OS/network enforcement from these checks.
The runner prints its run ID before preflight and each sample before launch.
Create `.agents/runtime/evaluation/<run-id>.stop` to stop between samples: the
active task (including both recovery/rollback phases) finishes and is recorded
before stopping. The report retains outcomes and a stop reason; it is not resumed.
Artifact tests are bounded checks, not a semantic proof of every sentence in an
answer. Source verification, memory persistence and boundary enforcement also
have independent engineering tests; model-written explanations alone are not proof.

Usage is summed from actual `turn.completed` events: total input includes cached
input, so caching is reported separately, not subtracted. Output already includes
reasoning; reasoning is reported separately and never added a second time.
Missing counters remain null, not zero. Completed tool item IDs are counted once;
the CLI event categories counted are documented in the runner. Cache state is
observed through counters, not assumed cold. Subagents are disabled in both arms.
Execution-policy denials can occur before tool-item events exist. Such runs stop
the suite and report tool calls as unavailable rather than claiming zero attempts.
Do not bypass host policies or weaken permissions to make an evaluation pass.
Permission words inside successful source reads are recorded as mentions, not
denials. Structured failures and failed commands with error-shaped output block
execution. Ambiguous error-shaped output (including PowerShell errors with exit
zero) stops for review without claiming that a policy denial was proven. This is
diagnostic classification, not an isolation enforcement mechanism.

Command observation decodes the CLI's rendered argv as data, then uses the native
PowerShell AST to distinguish invocations from search arguments and quoted text.
An `rg` search for `Invoke-WebRequest` is not a network call. Direct network and
Git transport invocations stop the run; unsupported shell wrappers, malformed
quoting and dynamic Git operations stop for review. This bounded observer does
not inspect transitive script behavior or prove network isolation. The configured
network restriction remains separate from observations.

Release grading independently requires successful workload and full Provider
validation before the local commit, in separate completed command events. The
native JSON receipt must cover every checkpoint check and match final input
content; the frozen baseline must emit its full-audit success output. These
requirements are visible to both arms. Reading scripts, using Changed, stale
receipts and post-commit checks do not pass. Command/output observation is bounded
evidence, not an adversarial proof that arbitrary shell output cannot be forged.

Acceptance requires all 36 candidate tasks to pass, all safety regressions to
pass, and successful paired samples to show median input reduction >=30 percent
and tool-call reduction >=20 percent. Disclose all failures and sample counts.
The comparison is `1 - candidate median / baseline median` over successful paired
tasks. Both arms use exactly the same pairs, including zero-tool tasks. Missing
counters block the efficiency gate; a zero median denominator is unavailable.
The runner emits both arms' pass/fail counts and exits nonzero on failed pilot
samples or failed full-suite targets. Baseline task failures remain visible but
do not automatically fail the candidate's 36-task quality gate; only pairs where
both arms succeeded enter efficiency calculations. Protocol changes invalidate
an in-progress run; formal runs require a clean committed source/protocol boundary.
Pilot completion is never acceptance. No partial or failed
run establishes the release's model-quality or efficiency targets.
