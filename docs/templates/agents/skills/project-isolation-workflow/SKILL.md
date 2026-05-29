---
name: project-isolation-workflow
description: Maintain repo-local Agents rules, deployment templates, memory, and controller/employee workflows.
---

# Project Isolation Workflow

Use this project-local skill for isolation, memory, deployment, multi-agent, handoff, skill-authoring, or repo maintenance.

## Route

1. Classify the request before reading more files.
2. Answer-only with no current repo-state claim: answer from loaded rules; run no command; compact closeout.
3. Before edits, release/deploy/git actions, or current repo-state claims: inspect `git status -sb`.
4. Read only the needed canonical file: `policy.yaml`, `workflows.yaml`, `schemas.yaml`, `deploy.yaml`, or `verify.yaml`.
5. Use `docs/agents/deploy.yaml` before copying/adapting rules to another authorized repo.
6. Use the smallest applicable `docs/agents/verify.yaml` profile.
7. Read detailed memory entries only when `docs/memory/index.md` points to a relevant lesson.
8. Keep durable project knowledge inside this repo unless the user explicitly asks for global Memory.

## Employee Quick Path

- Read assignment first.
- Stay inside assigned read/write scope and named project-local skills.
- Treat scope as behavioral-only unless tool/external enforcement is verified.
- Touch temp handoff cache only when assignment names exact path/action.
- Edit only assigned owned write scope.
- Return final report immediately when complete, blocked, or stopped.

## Guardrails

- Project-local skills live under `.agents/skills/`; do not create project-specific global skills.
- Do not intentionally use global/system skills or global Memory for normal project work.
- Do not access outside this repo unless exact path/action is authorized, or approved temp cache access is required.
- Report temp cache access as project-external.
- Do not claim hard isolation without current verified evidence.
- Keep deployable templates source-neutral.
- Workers require non-overlapping owned write scopes.
- Keep `AGENTS.md` and `SKILL.md` compact.

## Multi-Agent

On hire/spawn/delegate/parallel-agent requests:

1. Choose `session-managed`, `manual-detached`, or `cloud-or-automation`.
2. Prefer `manual-detached` for visible, controllable, non-blocking, longer local work.
3. Use `explorer` for read-only work; `worker` for bounded edits.
4. Give every worker normalized exclusive owned write scope and ownership matrix status.
5. If the employee may outlive context, run concurrently, or edit files, create/update the temp roster.
6. Final report is the completion notification.
7. Controller reviews reports and diffs before integration.

## Closeout

Always include:

```text
Isolation: GM <used/not used> | GS <used/not used> | XR <none/paths> | XW <none/paths>
```

For answer-only/no-change work, add only directly relevant facts. Expand only when files, verification, external access, durable knowledge, or claim scope require it.
