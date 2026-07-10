# Use English Trigger Rules With Semantic Matching
ID: M001
Date: 2026-05-28
Title: Use English trigger rules with semantic matching
Status: active
Confidence: high
Last Verified: 2026-07-10
Next Review Due: 2026-10-08
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
