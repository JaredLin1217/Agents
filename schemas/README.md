# Schemas

This directory owns machine-readable contracts for the Agents governance rules.

Initial scope:

- `docs/agents/workflows.yaml`
- `docs/agents/verify.yaml`
- `docs/agents/policy.yaml`
- `docs/agents/schemas.yaml`
- `docs/agents/version.yaml`
- `docs/agents/deploy.yaml`

The first schema contracts are standard JSON Schema documents with a small
supported subset used by `scripts/validate.ps1`:

- top-level `required`
- `properties.schema.const`

This gives the repo an immediate contract gate without adding package
dependencies. Full JSON Schema validation can be added later through the same
schema files.
