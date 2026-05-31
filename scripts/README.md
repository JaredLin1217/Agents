# Scripts

This directory owns repo-local executable checks and maintenance entry points.

Current command:

```powershell
.\scripts\validate.ps1
```

Release-audit command:

```powershell
.\scripts\validate.ps1 -Full
```

The validation entry point stays small and composable. It uses no external
package dependencies and runs focused checks for lightweight YAML syntax,
workflow YAML syntax, required file references, schema contracts, validation
fixtures, placeholder scans, durable English-only rules, and
runtime/source-state boundaries.

The `-Full` mode adds release-audit gates for diff hygiene, exact-pair drift,
deploy manifest integrity, template bundle coverage, project skill metadata,
and size budgets.

Full JSON Schema validation belongs in `schemas/` and can be added later
without changing the command entry point.
