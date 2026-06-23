# Schemas
This directory owns machine-readable contracts for the Agents governance rules.
Initial scope:
- `docs/agents/workflows.yaml`
- `docs/agents/verify.yaml`
- `docs/agents/policy.yaml`
- `docs/agents/schemas.yaml`
- `docs/agents/version.yaml`
- `docs/agents/deploy.yaml`
- `docs/agents/openai-foundations.yaml`
- `docs/agents/org.yaml`
- `docs/agents/model-policy.yaml`
- `docs/agents/dispatch.yaml`
- `docs/agents/workflow-artifacts.yaml`
- `docs/agents/context-compact.yaml`
- `docs/agents/collaborators.yaml`
- `docs/agents/core-system.yaml`
- `docs/agents/runtime-execution.yaml`
- `docs/agents/provider-adapters.yaml`
- `docs/agents/route-packs.yaml`
- `docs/agents/knowledge-footprint.yaml`
Schema contracts are standard JSON Schema documents with a small supported
subset used by `scripts/validate.ps1`:
- top-level `required`
- `properties.schema.const`
- `x-required-paths`
- `x-required-values`
- `x-required-contains`
This gives the repo an immediate contract gate without adding package
dependencies. A fuller JSON Schema validator can replace the lightweight
runner without changing the schema ownership model.
The enterprise dispatch schemas keep organization structure, model tier policy,
and dispatch protocol machine-checkable without tying the workflow to one
future-sensitive model ID.
The workflow artifact, context compact, collaborator, foundation creation,
runtime execution, provider adapter, route pack, and knowledge footprint schemas
keep local packets, approval gates, collection reports, compact resume state,
named thread window assignments, state boundaries, latency controls, evaluation
gates, and close evidence machine-checkable while runtime evidence stays local.
