# Scripts

This directory owns repo-local executable checks and maintenance entry points.

Current command:

```powershell
.\scripts\validate.ps1
```

The validation entry point stays small and composable. It uses no external
package dependencies and runs focused checks for lightweight YAML syntax,
workflow YAML syntax, required file references, schema contracts, validation
fixtures, placeholder scans, durable English-only rules, and
runtime/source-state boundaries.

Full JSON Schema validation belongs in `schemas/` and can be added later
without changing the command entry point.
