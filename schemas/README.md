# Schemas

This directory owns machine-readable contracts for the Agents governance rules.

Initial scope:

- `docs/agents/workflows.yaml`
- `docs/agents/verify.yaml`
- `docs/agents/policy.yaml`
- `docs/agents/schemas.yaml`
- `docs/agents/version.yaml`
- `docs/agents/deploy.yaml`
- `docs/agents/mcp.yaml`

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
