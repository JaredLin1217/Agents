# Use English Trigger Rules With Semantic Matching
ID: M001
Date: 2026-05-28
Title: Use English trigger rules with semantic matching
Status: active
Confidence: high
Source Commit: 8a2d46adf19d2ede1ca5cc5aff880ca5a4cc2a61
Content Hash: 3a5cba79ee8b8d4a84348a54447dca65fa830d3c9912f5081ba3d249506a61db
Checked At: 2026-08-06T01:25:07Z
Last Verified: 2026-08-06
Next Review Due: 2026-11-04
Update Trigger: Changes to durable language policy, semantic task routing, multi-agent triggers, or source references require revalidation.
Supersedes: none
Boundary: Applies to durable project rules and examples; runtime user messages may use any clear language.
Source Refs: `AGENTS.md`; `docs/agents/workflows.yaml`

## Trigger
Updating employee hiring trigger rules or examples.

## Context
Durable trigger rules must not store user-language literals and may otherwise introduce encoding-sensitive checks.

## Cause
Literal phrase matching confuses user-language examples with stable behavioral intent.

## Fix / Rule
Keep rules English and source-neutral. Runtime may treat clear hire, spawn, delegate, or parallel-agent equivalents as explicit requests.

## Verification
`AGENTS.md` and `docs/agents/workflows.yaml` use semantic intent without user-language trigger literals.

## Evidence
The current canonical workflow policy keeps durable rules English-only and routes multi-agent work by intent.

## Reuse when
Updating multi-agent triggers, templates, assignments, or command examples.
