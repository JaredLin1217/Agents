---
name: project-isolation-workflow
description: Maintain repo-local Agents rules, deployment templates, project memory, and controller plus employee workflows for isolated projects.
---

# Project Isolation Workflow

## Overview

Use this project-local skill for Agents isolation, memory, deployment, multi-agent, handoff, skill-authoring, or repo-local Codex maintenance. Canonical rules live in `docs/agents/*.yaml`; read only the relevant policy file(s) for the task.

## Routing

1. Read `AGENTS.md`.
2. Inspect `git status -sb` when scope permits.
3. Select only the needed canonical file(s): `policy.yaml`, `workflows.yaml`, `schemas.yaml`, `deploy.yaml`, or `verify.yaml`.
4. Use `docs/agents/deploy.yaml` before copying or adapting Agents rules into another authorized repository.
5. Use the smallest applicable profile in `docs/agents/verify.yaml`; reserve release-grade gates for commit, tag, release, deploy, push, or no-deduction claims.
6. Read detailed memory entries only when `docs/memory/index.md` points to a relevant verified lesson.
7. Keep all new durable project knowledge inside this repository unless the user explicitly asks to use global Memory.

## Employee Quick Path

For scoped employee assignments:

1. Read the assignment first.
2. Read only assigned repository paths and required project-local skills.
3. Treat read scope and write scope as hard behavioral boundaries unless verified tool or external enforcement is provided.
4. Do not touch the OS temp handoff cache unless the assignment gives the exact derived temp path and event permission.
5. Do not edit repository files unless assigned an owned write scope.
6. Return the required final report immediately when complete, blocked, or stopped.

## Hard Guardrails

- Project-local skills live under `.agents/skills/`; do not create project-specific skills in global Codex folders.
- Do not intentionally use global/system skills for normal project work.
- Do not use global Memory as project context or storage unless the user explicitly asks.
- Do not access filesystem paths outside this repository unless the user authorizes the exact path and action, or the access is the approved OS temp handoff cache.
- The OS temp handoff cache is project-external and must be reported when used.
- Do not claim hard isolation without verified evidence from `docs/agents/policy.yaml` and `docs/agents/schemas.yaml`.
- Deployable templates must stay source-neutral. Fix pollution before closeout.
- Worker assignments require an ownership matrix; multi-worker assignments require non-overlapping ownership before launch.
- Keep `AGENTS.md` and `SKILL.md` compact; move durable detail to the policy pack.

## Multi-Agent Trigger

When the user asks to hire, spawn, delegate, request parallel-agent work, or uses a clear semantic equivalent:

1. Choose `session-managed`, `manual-detached`, or `cloud-or-automation`.
2. Prefer `manual-detached` for sidebar-visible, user-controllable, non-blocking, longer-running local work.
3. Assign `explorer` for read-only investigation or `worker` for bounded implementation.
4. Define normalized exclusive owned write scope and record an ownership matrix for every worker.
5. Include the assignment fields from `docs/agents/schemas.yaml`.
6. If an employee may survive controller compaction, run beside another employee, or edit files, create or update the temp roster with runtime id, nickname, status, and ownership before continuing.
7. Tell employees that final report is the completion notification.
8. Poll active employees at task boundaries before overlapping edits or final closeout.
9. Close employees by runtime id when their useful context expires; archive or history cleanup is separate and requires explicit user authorization when it touches Codex internals.
10. Controller reviews reports and diffs before integration.

## Closeout

After meaningful work, report changed files, verification, remaining risk, durable-knowledge impact, and:

```text
Isolation: GM <used/not used> | GS <used/not used> | XR <none/paths> | XW <none/paths>
```

Name the verified claim scope from `docs/agents/verify.yaml`: static policy pack, runtime multi-agent, hard isolation, or not claimed.
Report any system/global resources outside global Memory or Global Skills separately when used.
