# Agents 5.0 review

Reviewed on 2026-11-05 from the clean `main` checkout at 46d132f. The project
purpose remains a portable governance workflow for authorized engineering:
versioned rules, checked knowledge, recoverable work and owned deployment
changes. The review covers the 1.x through 4.x history and the current v4 tree.

## Decisions

| Area | Keep | Remove or replace |
|---|---|---|
| Project purpose | Rules, knowledge, task recovery and deployment ownership | Hosted multi-tenant service, billing and background memory service are outside this release |
| Instructions | Short root guidance, scoped skills and native precedence | Historical roster, controller, dispatch, fixed model, worker, compaction and score rules |
| Memory | Immutable source-checked records and explicit retirement | Native memory as an authority or permission source |
| Tasks | Revisioned goals, acceptance, receipts, Git/file snapshots and action history | Silent v3/v4 fallback in the active v5 reader |
| Runtime | Registered runs, state, ledger, retention, cleanup preview and tombstones | Wholesale runtime clearing and unregistered payloads |
| Distribution | Cross-platform PowerShell CLI and Codex plugin | Implicit hook activation, telemetry and secrets in packages |
| Validation | Plan, affected checks, one delivery checkpoint and committed evidence | Full regression on every edit and synthetic quality scores |

## History and drift

Agents 1.x established isolation and reusable rules. Agents 2.x added ledgers,
dispatch and deployment readiness. Agents 3.x removed mandatory routing,
model-host probes, comparison runners and synthetic scores in favor of native
Codex skills. Agents 4.x added immutable knowledge, task revisions, runtime
retention and release evidence. v5 keeps the purpose while removing the remaining
legacy readers and packaging the workflow for repeatable cross-project use.

The current checkout was still v4.0.0 with a PowerShell-only command surface,
Windows-focused regression fixtures, a v3 deployment manifest schema, no unified
CLI, and no portable plugin manifest. The current source registry was due for a
fresh review; official content hashes were refreshed on 2026-11-05.

## Official boundary

GPT-6.1 Sol supports low, medium, high, xhigh and max reasoning and requires the
Responses API for tool calling. These are API facts, not a forced Codex host
configuration. The GPT-6 prompting guide is a family starting point based on
Astra observations; it is not measured Sol behavior.

Codex instruction files merge by directory and support overrides. Skills use
progressive disclosure and concise descriptions. Native memory is a local,
generated recall layer with v1/v2 storage controls. Hooks use trusted JSON event
handlers and must not depend on transcript internals. Plugins use a portable root
manifest with a Codex compatibility overlay; lifecycle-hook bundles remain local
opt-in artifacts rather than public plugin content.

## Commercial readiness boundary

v5 makes the package supportable and distributable without pretending to be a
hosted SaaS product. The release must provide a stable CLI, JSON/exit contracts,
v4 migration, root/dot layout support, rollback, deterministic plugin packaging,
platform support evidence, privacy-safe diagnostics, no telemetry by default and
clear support/security documents. External Consumer upgrades remain explicit.
