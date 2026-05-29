# Isolation Audit

Use this runbook when isolation, Global Memory, Global Skill, project-external access, hard-isolation claims, or closeout reporting are in scope.

1. Read `AGENTS.md`.
2. Default runtime enforcement to `behavioral-only`.
3. Check `docs/agents/policy.yaml` for exact isolation and external access rules.
4. If the user asks for hard isolation or a guarantee, use `docs/hard-isolation-evidence.template.md` and collect verified evidence before claiming `tool-enforced` or `externally-enforced`.
5. Report Global Memory, Global Skill, project-external reads, and project-external writes in closeout.

References: `docs/agents/policy.yaml`, `docs/agents/schemas.yaml`, `docs/hard-isolation-evidence.template.md`, `docs/agents/verify.yaml`.
