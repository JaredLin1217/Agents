# Decision 0003: Multi-Agent Validation Baseline

## Decision

Source-project validation history is non-deployable. Target projects must verify their own multi-agent maturity.

## Reason

Employee status, validation history, local runtime IDs, and temp handoff records are project state. Copying them into another project pollutes the target.

## Consequences

- Templates exclude source employee history and validation results.
- Deployment validation searches for concrete source/target literals.
- Multi-agent behavior remains behavioral-only unless stronger runtime or external enforcement is verified.
