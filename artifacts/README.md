# Artifacts

This directory defines the local artifact boundary for traces, evals, and audit
outputs.

Planned subdirectories:

- `traces/`
- `evals/`
- `audit/`

Runtime artifacts should be ignored unless a specific file is intentionally
promoted to a durable fixture, summary, or template. Do not store secrets,
machine-local live state, or Codex runtime data here.
