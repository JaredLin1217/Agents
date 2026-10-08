# Agents 4.0 review

Reviewed on 2026-10-08 against baseline a20e23a (Agents 3.0.0). The project is an
operating workflow for authorized engineering: versioned rules, source-checked
knowledge, recoverable unfinished tasks and explicitly owned deployment assets.
This purpose is retained. The change scope is Agents and its deployment tooling;
no external Consumer, global Codex settings or generated native memory was edited.

## Baseline findings

The review covered every one of the 45 tracked baseline files and the ignored
runtime inventory. agents.json is the canonical version source. v3 had one active
knowledge record and substring-only query, overwriteable task state without
requirement/acceptance/receipt history, unregistered runtime packages/backups,
adjacent atomic JSON staging and no retention/deletion ledger. The model/configuration
source entries expired on 2026-10-05. Missing or stale release evidence returned
ordinary success strings. Documentation asserted local settings absent from the
checkout. The earlier baseline run lacked a retained complete receipt, so it is
not treated as a successful 2026-10-08 full checkpoint.

## Rules audit

| Convention | Decision | Reason and replacement |
|---|---|---|
| Latest user goal and meaningful corrections | Retain | Checkpoints append goal and acceptance history; recall cannot replace current authorization. |
| Inspect actual Git/files and preserve other work | Retain | Resume compares HEAD, index, status and file hashes; completed operations never replay. |
| Mandatory rules in AGENTS.md | Retain | Native instruction discovery supports concise versioned constraints; specialized steps load through skills. |
| Resolver mandatory budget/expansion instruction | Remove | Optional discovery remains a bounded helper, with gaps; it is not complete impact or a test waiver. |
| Fixed two-worker limit | Remove | Single-agent default and explicit delegation authorization remain; actual host availability governs limits. No workers used here. |
| Fixed model/reasoning/64k compaction and disabled memory claims | Remove | No local configuration exists in the baseline; API model settings do not establish Codex host configuration. |
| Hard 2 KiB rules / 15 KiB validator gates | Remove | Keep concise guidance and measure bytes without arbitrary success/failure limits. |
| Immutable verified project knowledge | Extend | v4 adds provenance kinds, modules/tags/files, multiple query terms, review deadlines and retraction IDs. |
| Source drift/conflict/retirement suppression | Retain | Expired or broken replacements cannot revive retired facts; duplicate active keys pause recall. |
| Reviewed knowledge promotion workflow | Extend | Approved workflow automatically saves reviewed reusable nonsensitive facts; hypotheses remain runtime. This is a reviewer obligation plus mechanical checks, not proof of semantic truth. |
| Native memory as a required or disabled layer | Replace | Supplementary recall; necessary rules and verified project records keep explicit file sources. |
| Checkpoint truth and no repeated unchanged checks | Retain | One registry persists each check once; Changed follows affected work and Checkpoint defines delivery. Live authority/remote/side effects always need fresh observation. |
| Missing/stale evidence treated as passed | Replace | needs_review, separate release_ready, and RequireReleaseReady failing the publication gate. |
| Target ownership, exact previews and rollback integrity | Retain | Both layouts retain unowned/modified-file rejection, idempotence, interruption blocking and original-byte validation. |
| Runtime as an ignored loose folder | Replace | Runs/state/ledger, registered hashes/dependencies, 7/30/90 retention, pins and guarded deletion tombstones. |
| Global state and unrelated targets excluded | Retain | Templates do not activate hooks, edit Codex state or upgrade external Consumers. |
| Untrusted memory/docs/tool results | Clarify | Retrieved content is data and cannot authorize actions. |
| User language; English durable guidance | Retain | Natural responses stay in the user's language; durable rules, docs and templates are English. |

Native discovery and progressive loading are supported by
[AGENTS.md documentation](https://learn.chatgpt.com/docs/agent-configuration/agents-md)
and [skills documentation](https://learn.chatgpt.com/docs/build-skills). Delegation
remains an authorized task choice using [native subagents](https://learn.chatgpt.com/docs/agent-configuration/subagents),
with no inferred permission from a recalled lesson.

## GPT-6.1 Sol reference and limits

The specified review model is [GPT-6.1 Sol](https://developers.openai.com/api/docs/models/gpt-6.1-sol).
Its API reasoning levels are low, medium (default), high, xhigh and max. Tool calls
use Responses; Chat Completions supports requests without tools. The model page
lists a 1.05M context, 922K maximum input and 128K maximum output. These are model
API capabilities, not settings imposed on this repository or Consumer hosts.

The [GPT-6 family prompting guide](https://developers.openai.com/api/docs/guides/latest-model#prompting-best-practices)
informs outcome-focused instructions, appropriate initiative and removal of
conflicting obsolete guidance. Some described behavior is based on Astra. Applying
that advice to Sol is a design inference; no Sol-versus-Astra task evaluation or
measured token saving was run. Hosts may expose different controls, as documented
in the [configuration reference](https://learn.chatgpt.com/docs/config-file/config-reference).
The implementation does not change any such host setting.

## Knowledge and continuation

The three stores have different roles: versioned mandatory guidance, immutable
verified knowledge, and runtime task snapshots. Knowledge sources distinguish
file snapshots, officially reviewed documents and explicitly recorded user
choices. Hashes, locators, verification and freshness accompany each conclusion.
Automatic promotion is opt-in at the mechanical CLI boundary and the approved
default in the project skill, after semantic review. Official automatic promotion
requires a matching live source check. Active records need durable project evidence.

M001 remains unchanged; its conclusion was rechecked against current rules and
published as M002 with a supersession link. New revisions and withdrawals use new
IDs. Query/index paths never bypass record verification. Native generated memory
is supplementary per [Codex Memories](https://learn.chatgpt.com/docs/customization/memories).
Agents does not modify the generated user-memory files.

Task Save is revision-checked under an exclusive lock. Requirements changes append
history and each checkpoint is a separate immutable file. Receipt dependencies
keep evidence beyond 30 days while a task needs it. Resume reports actual drift,
unusable knowledge/evidence and interrupted saves, without interpreting a plan as
an external action to execute. Multiple candidates require explicit selection.
Complete starts the task's 90-day period; deletion removes its completed pointer
but leaves provenance. Plan/read-only operations inspect without promotion or cleanup.

## Runtime and hooks

All new Agents payloads use registered run directories; state and ledger remain
separate. Success, failure and interruption are recorded. Failed work and rollback
options stay protected until explicit resolution/retirement. Cleanup has a stable
canonical digest across processes, rechecks exact trees/record hashes/dependencies
and locks, and rejects unknown content, changed bytes or links. JSON staging stays
inside runtime and carries immutable flushed start/end frames. Interrupted frames
need explicit reconciliation. This protects owned files from accidental deletion;
it is not adversarial operating-system isolation. Git, native state and arbitrary
external caches are outside scope unless inside an explicit disposable test target.

[Native hooks](https://learn.chatgpt.com/docs/hooks) supply a JSON event interface
and trust review. The delivered template resolves the Git root and both layouts;
SessionStart provides bounded verified recall, PreCompact inspects saved state,
and Stop can request one continuation per turn. It never parses full transcript
contents, promotes facts, cleans payloads or replays actions. Explicit commands
provide the same inspection without activation. Native trust/actual live Codex
hook activation was not performed; local wire/command tests do not imply activation.

## Evidence and migration

Project/knowledge/task/validation/runtime contracts advance to v4. Release evidence
advances to v6 and retains v5 readability; unchanged deployment/ownership and source
registry structures remain v3. Legacy entries/tasks are not blindly overwritten;
Migrate needs newly reviewed input. Proven legacy packages can migrate only after
complete manifest/hash matching; unknown contents remain for review. Existing
Consumers need a separately authorized target upgrade.

Validation receipts persist before output, including setup failures. Publication
needs clean committed source, generated evidence, schema/digest verification and
a fresh release gate. Uncommitted implementation work never gains fabricated v4
release evidence. Delivery may therefore report source checks passed with evidence
needs_review and release_ready=false. Formal evidence is versioned and never TTL-deleted;
its readiness still expires after 30 days and source changes invalidate it.

## Verification scope

The checkpoint registry runs legacy deployment/memory regression and the v4
contracts once each. Tests cover both layouts, Chinese/spaced/subdirectory paths,
no-write previews, ownership conflicts, idempotence, full rollback and damaged
backups; knowledge drift/expiry/duplicates/conflicts/retraction/retirement; task
revision/index/goal/history/receipt behavior; successful/failed/interrupted runtime,
fixed-clock expiry boundaries, pins, hash/unknown/link/lock refusal; and native JSON
hook read-only/reentry/compact behavior. Individual persisted results determine
acceptance, not this coverage description. Inspect the final runtime receipt for
actual results and the reported environment. External project deployment, live
hook trust activation, non-Windows execution and model behavior accuracy remain
outside that offline evidence. No universal future recall/correctness guarantee.

## Official review provenance

All eight referenced official documents were fetched and relevant sections read
on 2026-10-08. `docs/agents/official-review-2026-10-08.json` records URLs and fetched
content hashes; `sources.json` records reviewed dates/deadlines. Dates were changed
only after those reads. Raw fetch receipts stay registered runtime diagnostics;
this report and durable metadata do not depend on their later retention.

## Baseline inventory

Every baseline tracked path below was inspected. Scripts/schemas/tests define
behavior; rules/skills/runbooks explain boundaries; GitHub/support/legal files
were checked for stale conventions and otherwise preserved where unaffected.

- `.agents/deploy-ignore`
- `.agents/skills/project-checkpoint/SKILL.md`
- `.agents/skills/project-memory/SKILL.md`
- `.gitattributes`
- `.github/ISSUE_TEMPLATE/bug_report.yml`
- `.github/ISSUE_TEMPLATE/config.yml`
- `.github/ISSUE_TEMPLATE/deployment.yml`
- `.github/ISSUE_TEMPLATE/documentation.yml`
- `.github/pull_request_template.md`
- `.github/workflows/checkpoint.yml`
- `.gitignore`
- `AGENTS.md`
- `CHANGELOG.md`
- `CODE_OF_CONDUCT.md`
- `CONTRIBUTING.md`
- `LICENSE`
- `NOTICE`
- `README.md`
- `SECURITY.md`
- `SUPPORT.md`
- `agents.json`
- `docs/agents/deployment.json`
- `docs/agents/sources.json`
- `docs/evidence/releases/v3.0.0-runtime-evidence.json`
- `docs/memory/entries/M001-semantic-intent.json`
- `docs/runbooks/agents-operator-guide.md`
- `docs/v3-upgrade.md`
- `schemas/deployment.schema.json`
- `schemas/knowledge.schema.json`
- `schemas/managed.schema.json`
- `schemas/project.schema.json`
- `schemas/release-evidence.schema.json`
- `schemas/sources.schema.json`
- `schemas/task-state.schema.json`
- `scripts/agent-checks.ps1`
- `scripts/agent-core.ps1`
- `scripts/agent-deployment.ps1`
- `scripts/capture-runtime-evidence.ps1`
- `scripts/deploy-agents-workflow.ps1`
- `scripts/export-release-package.ps1`
- `scripts/project-memory.ps1`
- `scripts/resolve-agent-context.ps1`
- `scripts/task-state.ps1`
- `scripts/validate.ps1`
- `tests/test-workflow.ps1`
