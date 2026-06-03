# Changelog
All notable changes to this repository are documented here.
## Unreleased
## 2.2.1 - 2026-06-03
- Added the Context Compact Layer with canonical auto-compaction, handoff,
  resume, and subagent closeout summary rules.
- Added context compact schema and template mirror coverage.
- Added validation coverage for required compact summary fields, raw transcript
  exclusion, subagent closeout counts, runtime compact event boundaries, and
  route guardrails.
- Updated deployment, version metadata, and README documentation for context
  compact compatibility while preserving V2 behavior.
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
- Updated public version documentation to `2.2.0` while preserving V2
  compatibility.
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
- Updated public version documentation to `2.1.0` while preserving V2
  compatibility.
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
