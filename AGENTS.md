# Project Operating Rules

## Purpose

- Project-local Codex operating rules for an isolated Agents workflow.
- Keep this tiny; canonical detail is in `docs/agents/*.yaml`.
- Write rules, docs, skills, and templates in English only.

## Start

- Current repo evidence wins over prior chat or Memory.
- Before edits, run `git status -sb` when feasible and protect existing changes.
- Do not assume project mode, stack, scripts, runtime, or architecture until repo files define them.
- Use repo scripts when present; use `docs/agents/verify.yaml` for Agents workflow checks.
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

- `docs/agents/policy.yaml`: authority, isolation, editing, closeout, hard gates.
- `docs/agents/workflows.yaml`: memory, multi-agent, handoff, skills, maintenance.
- `docs/agents/schemas.yaml`: assignment, report, status, event, lease, evidence fields.
- `docs/agents/deploy.yaml`: deployment allowlist, blocklist, steps, validation.
- `docs/agents/verify.yaml`: no-script checks, size gates, no-deduction audit, drift.
- `docs/templates/agents/`: source-neutral deployment bundle.

## Multi-Agent

- Controller integrates; employees do not merge or reconcile others' work.
- Launch runtime employees only after an explicit user hire, spawn, delegation, parallel-agent request, or clear semantic equivalent.
- For hire/spawn requests, choose `session-managed`, `manual-detached`, or `cloud-or-automation` before assigning.
- Prefer `manual-detached` for visible, controllable, non-blocking, or longer local work.
- Employee assignments must state mode, role, goal, enforcement, ownership, scopes, edit permission, skills, allowed tools, verification, status-event rule, completion notification, and final report schema.
- If an employee may outlive controller context, compact, run beside another, or edit files, keep a temp roster with runtime id, nickname, status, ownership.
- Workers require normalized owned write scopes and an ownership matrix; multiple workers also require non-overlap evidence. Poll or close active workers before editing their owned paths.

## Closeout

Every final reply must include:

```text
Isolation: GM <used/not used> | GS <used/not used> | XR <none/paths> | XW <none/paths>
```

Also report changed files, verification, risk, durable-knowledge impact, and system/global resources when used.
Name the verified claim scope: static policy pack, runtime multi-agent, hard isolation, or not claimed.
