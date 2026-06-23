# Changelog
All notable changes to this repository are documented here.
## Unreleased
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
