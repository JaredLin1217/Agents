# Isolation Audit

Use this runbook when isolation, Global Memory, Global Skill, project-external access, hard-isolation claims, or closeout reporting are in scope.

1. Read `AGENTS.md`.
2. Default runtime enforcement to `behavioral-only`.
3. Check `docs/agents/policy.yaml` for exact isolation and external access rules.
4. If the user asks for hard isolation or a guarantee, collect verified evidence before claiming `tool-enforced` or `externally-enforced`.
5. Report Global Memory, Global Skill, project-external reads, and project-external writes in closeout.

Key references:

- Isolation policy: `docs/agents/policy.yaml`
- Evidence schema: `docs/agents/schemas.yaml`
- No-script checks and no-deduction audit: `docs/agents/verify.yaml`
