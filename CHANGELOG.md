# Changelog
All notable changes to this repository are documented here.
## Unreleased
## 2.9.0 - 2026-08-06
- Added bounded, pointer-first context intelligence with deterministic routing,
  file and line evidence, dependency and test impact, provenance, confidence,
  content hashes, freshness, gaps, and verification recommendations.
- Integrated context evidence into change-aware validation so evidence can
  increase verification scope while stale, degraded, unsupported, conflicting,
  dirty, and parse-failure states trigger controlled full-validation fallback.
- Replaced knowledge footprint, compact context, and runtime evidence contracts
  with current-only v3, v3, and v4 formats; removed the superseded release
  evidence artifact and compatibility branches.
- Added a repeatable eight-task, three-run A/B practice suite with accuracy,
  critical-impact recall, precision, context-byte, tool-call, determinism, and
  fallback acceptance gates.
- Extended runtime task state with route, verified assumptions, change boundary,
  remaining steps, and recovery pointers for bounded long-task resume.
- Kept all context indexes and raw reports in ignored runtime storage and
  blocklisted them from deployment and release packages. CodeGraph remains a
  research influence only; no CodeGraph runtime dependency was added.
## 2.8.0 - 2026-07-10
- Replaced the runtime evidence v2 contract with v3 so content digests
  explicitly count every intended tracked or untracked file.
- Reworked the official foundation layer around current Codex instructions,
  skills, memory, subagent, compaction, token-counting, caching, and evaluation
  guidance with a 90-day source review contract.
- Added freshness-bound, evidence-backed durable memory with index-first
  retrieval, explicit confidence and review metadata, and current-evidence
  override rules.
- Added change-aware `Fast`, `Policy`, and `Full` validation selection so
  routine work pays only for the evidence its risk requires.
- Moved quality scoring and repo-size accounting out of the main validation
  orchestrator, reducing it below 100 KiB while keeping one canonical gate.
- Strengthened progressive disclosure, context budgets, one-state-owner rules,
  delegation cost gates, stable prompt-prefix guidance, and tool-output
  trimming to reduce token use and coordination errors.
- Removed current-release version hardcoding from runtime evidence validation
  and aligned canonical schemas, templates, operator guidance, and release
  evidence on the latest-only 2.8 contract.
## 2.7.0 - 2026-06-25
- Added v2 runtime evidence bound to source commit, content digest, working-tree
  state, command timings, and an explicit T2 current-repo practice tier.
- Added the operator guide and practice suite while continuing to split runtime
  and route-pack checks out of the main validator.
## 2.6.2 - 2026-06-24
- Added repeatable runtime evidence capture for self-test, current project
  dry-run, and full validation.
- Added a runtime evidence schema and sanitized v2.6.2 release evidence
  contract.
- Added source freshness fields and overdue checks for the OpenAI foundation
  source matrix.
- Split size gates and release evidence checks out of the main validator to
  reduce maintenance hotspots.
## 2.6.1 - 2026-06-23
- Stabilized the 2.6 foundation creation release without changing the core
  workflow contract.
- Added the OpenAI source matrix for official capability boundaries and drift
  risk.
- Split evidence template coverage into a helper and added runtime dry-run
  evidence templates.
- Tightened size gates for rule, skill, canonical YAML, and validation script
  headroom.
## 2.6.0 - 2026-06-23
- Added the Foundation Creation Layer for official-docs-first OpenAI capability
  design, schema-first outputs, explicit state ownership, tool boundaries,
  latency controls, evaluation gates, fallback plans, and cleanup rules.
- Added canonical and template `docs/agents/openai-foundations.yaml` contracts
  with schema validation and route-level verification.
- Removed the retired optional external connector layer from canonical docs,
  template mirrors, schemas, public README, structure maps, and validation
  gates.
- Updated scoring and readiness checks so foundation creation is validated as a
  first-class route instead of passive documentation.
## 2.5.1 - 2026-06-05
- Added cross-project runtime resilience for deployment and verification across
  multiple target repositories without sharing temp locks or route-pack output.
- Added deployment layout profiles for `root-layout`, `dot-agents-layout`, and
  `auto` detection, with mixed canonical path detection.
- Added target dirty snapshot protection so deployments only change the
  allowlisted Agents file set, target-local environment bootstrap, and
  deployment report.
- Made `scripts/agents-cleanup.ps1` part of the mandatory core deployment set
  and added cleanup capability checks to deployment reports and validation.
- Updated runtime execution evidence with deployment evidence, event summaries,
  verification refs, risk lists, and resume pointers for cross-window recovery.
- Updated route-pack and validation temp output to use per-project and per-run
  status roots while keeping deterministic route-pack hashes stable.
## 2.5.0 - 2026-06-03
- Repositioned the project as `2.5.0 Core Runtime System` for repo-local AI
  workflow routing, dispatch, collaborator windows, context compact, workflow
  artifacts, runtime evidence, deployment, validation, and release export.
- Added canonical core system, runtime execution, provider adapter, route pack,
  and knowledge footprint policies with schema contracts and template mirrors.
- Added `scripts/agents-runtime.ps1` for local execution run evidence,
  approvals, results, escalations, collection, verification, and cleanup.
- Added `scripts/export-route-pack.ps1` for deterministic minimal route pack
  manifests without model calls or live runtime writes.
- Strengthened validation for core runtime integrity, route pack determinism,
  runtime blocklists, version alignment, retired positioning residue, approval
  gates, and cleanup evidence.
- Updated deployment and release package contracts to block runtime evidence,
  live thread ids, provider sessions, API keys, `.workflow/`, and local Codex
  configuration.
## 2.3.0 - 2026-06-03
- Added the Collaborator Window Dispatch Layer for named, recoverable, and
  archivable Codex department-leader work sessions.
- Added collaborator canonical YAML, schema, template mirror, route, version,
  capability boundary, dispatch, workflow, and verification coverage.
- Blocked live thread ids, collaborator window state, and
  `.agents/runtime/collaborators.jsonl` from deployable and releasable content.
- Updated public documentation for collaborator commands, leader mapping,
  runtime-only thread evidence, and token-saving cross-window handoff behavior.
## 2.2.1 - 2026-06-03
- Added the Context Compact Layer with canonical auto-compaction, handoff,
  resume, and subagent closeout summary rules.
- Added context compact schema and template mirror coverage.
- Added validation coverage for required compact summary fields, raw transcript
  exclusion, subagent closeout counts, runtime compact event boundaries, and
  route guardrails.
- Updated deployment, version metadata, and README documentation for context
  compact resume behavior.
## 2.2.0 - 2026-06-02
- Added the Supervised Workflow Artifact Layer with canonical workflow
  artifact routing, local workflow state, packets, results, approval gates,
  collection reports, and final reports.
- Added workflow artifact schema and template mirror coverage.
- Added `scripts/agents-workflow.ps1` for new, verify, collect, simulate, and
  normalize workflow artifact actions without external dependencies.
- Added validation coverage for artifact-backed dispatch smoke tests, approval
  gate guardrails, direct worker report rejection, route regression, and runtime
  artifact blocklists.
- Updated deployment and release rules to exclude `.agents/runtime/workflows/`
  and `.workflow/` from deployable and releasable content.
- Updated public version documentation to `2.2.0`.
## 2.1.0 - 2026-06-01
- Added the Enterprise Dispatch Layer with canonical organization, model policy,
  and dispatch YAML files.
- Added controller-to-department-leader assignment, leader-owned internal
  dispatch, department reports, and escalation record rules.
- Added tier-first model policy so departments bind to capability tiers before
  replaceable concrete model IDs.
- Added enterprise dispatch schema contracts, template mirrors, deployment file
  coverage, and validation checks.
- Added clean release package export with manifest version, commit, file list,
  file hashes, package hash, and local-state exclusions.
- Updated public version documentation to `2.1.0`.
## 2.0.0 - 2026-06-01
- Added deployment-time Agents workflow version extraction and deployment
  report alignment from `docs/agents/version.yaml`.
- Documented the current public workflow version and canonical version source
  in the GitHub README.
- Added validation that the public README workflow version stays aligned with
  `docs/agents/version.yaml`.
- Added Apache-2.0 licensing, project copyright attribution, and public
  warranty disclaimer.
- Updated the tracked repository size gate for the public documentation and
  licensing footprint.
- Added push automation that regenerates the public GitHub update log from git
  history and commits it back after validation.
- Expanded public GitHub documentation for project purpose, quick start,
  deployment, validation, support, security, and contribution workflow.
- Added public issue and pull request templates.
## 2026-06-01
- Added compact Agents runtime routing through `docs/agents/ai-runtime.yaml`.
- Added deployable template mirror for the compact runtime route.
- Updated validation and deployment rules to include the AI runtime file.
