# Project Operating Rules

## Purpose

- This repo defines a portable, project-isolated Agents workflow.
- Keep this file tiny; canonical detail is in `docs/agents/*.yaml`.
- Write repo rules/docs/skills/templates in English only.

## Start

- Current repo evidence wins over prior chat or Memory.
- Before edits, run `git status -sb` when scope permits and protect user or parallel-agent changes.
- Do not assume project mode, framework, scripts, runtime, or architecture until repo files define them.
- Use repo-defined scripts when present; use `docs/agents/verify.yaml` for Agents workflow checks.
- Use `.agents/skills/project-isolation-workflow/SKILL.md` for isolation, memory, deployment, multi-agent, skill, or maintenance tasks.

## Guardrails

- Global Memory: do not use for normal project work.
- Global Skills: do not intentionally use for normal project work. `.agents/skills/**/SKILL.md` is project-local and allowed.
- External filesystem: do not access paths outside this repo unless the user authorizes the exact path/action, or the path is `%TEMP%/codex-agent-status/<project-id>/` for agent handoff.
- Temp handoff cache is volatile, project-external, and must be reported when used.
- Repo rules are behavioral, not a sandbox. Do not claim hard isolation without verified tool, OS, account, cloud, or runtime evidence.
- Another project's state belongs in that project, not in this repo.
- Do not hand-edit `.git/`, generated output, caches, build output, vendored files, runtime copies, or live Codex environment state unless explicitly targeted.

## Canonical Files

- `docs/agents/policy.yaml`: authority, isolation, editing, placement, closeout, hard gates.
- `docs/agents/workflows.yaml`: memory, multi-agent, handoff, skills, maintenance.
- `docs/agents/schemas.yaml`: assignment, report, status, event, lease, evidence, memory, skill fields.
- `docs/agents/deploy.yaml`: deployment allowlist, blocklist, steps, validation.
- `docs/agents/verify.yaml`: no-script checks, size gates, no-deduction audit, drift checks.
- `docs/templates/agents/`: source-neutral deployment bundle.

## Multi-Agent

- Controller integrates; employees do not merge or reconcile others' work.
- For hire/spawn requests, choose `session-managed`, `manual-detached`, or `cloud-or-automation` before assigning.
- Prefer `manual-detached` for sidebar-visible, user-controllable, non-blocking, or longer-running local work.
- Employee assignments must state mode, role, goal, enforcement, ownership, scopes, edit permission, skills, allowed tools, verification, status-event rule, completion notification, and final report schema.
- Multiple workers require non-overlapping owned write scopes. Poll or close active workers before editing their owned paths.

## Closeout

Every final reply must include:

```text
Isolation: GM <used/not used> | GS <used/not used> | XR <none/paths> | XW <none/paths>
```

Also report changed files, verification, risk, durable-knowledge impact, and system/global resources when used.
