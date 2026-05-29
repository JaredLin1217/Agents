# Project Operating Rules

## Purpose

- Repo-local Codex rules for an isolated, deployable Agents workflow.
- Keep this file small. Detailed rules live in `docs/agents/*.yaml`.
- Durable rules, docs, skills, and templates must be English-only.

## Fast Path

- First classify the request: answer-only, scoped edit, policy maintenance, release/deploy, employee, or hard-isolation claim.
- Answer-only with no current repo-state claim: do not run commands or load policy files just to close out.
- Before edits, release/deploy/git actions, or current repo-state claims, inspect git state and protect existing changes.
- Use the smallest applicable profile in `docs/agents/verify.yaml`; full gates are only for commit/tag/release/deploy/push/audit/no-deduction claims.
- Use `.agents/skills/project-isolation-workflow/SKILL.md` for isolation, memory, deployment, multi-agent, skill, or maintenance tasks.

## Guardrails

- Global Memory: not used for normal project work.
- Global Skills: not intentionally used for normal project work; `.agents/skills/**/SKILL.md` is project-local.
- External filesystem: no access outside this repo unless the user authorizes exact path/action, except the approved temp handoff cache.
- Temp handoff cache: `%TEMP%/codex-agent-status/<project-id>/`; report use as XR/XW.
- Repo rules are behavioral, not a sandbox. Claim hard isolation only with verified runtime/tool/OS/account/cloud evidence.
- Do not hand-edit `.git/`, generated output, caches, build output, vendored files, runtime copies, or live Codex environment state unless explicitly targeted.

## Key Files

- `docs/agents/policy.yaml`: authority, isolation, editing, closeout.
- `docs/agents/workflows.yaml`: memory, multi-agent, handoff, maintenance.
- `docs/agents/schemas.yaml`: assignment/report/status/evidence fields.
- `docs/agents/deploy.yaml`: deployment allowlist/blocklist.
- `docs/agents/verify.yaml`: verification profiles and gates.
- `docs/templates/agents/`: source-neutral deployment bundle.

## Multi-Agent

- Controller integrates; employees do not merge or reconcile others' work.
- Launch employees only after explicit hire/spawn/delegation/parallel-agent request or clear semantic equivalent.
- Prefer `manual-detached` for visible, controllable, non-blocking, longer local work.
- Workers need exclusive normalized write scope and an ownership matrix. Poll or close active workers before editing their owned paths.

## Closeout

Always include:

```text
Isolation: GM <used/not used> | GS <used/not used> | XR <none/paths> | XW <none/paths>
```

For answer-only/no-change work, keep closeout compact. Expand only for file changes, verification, risks, external access, durable knowledge, or explicit claim scope.
