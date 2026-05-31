---
name: project-isolation-workflow
description: Maintain repo-local Agents rules, templates, memory, deployment, and multi-agent workflows.
---

# Project Isolation Workflow

Use this project-local skill as a compact router for isolation, memory, deployment, multi-agent, handoff, skill-authoring, or repo maintenance procedures. Canonical rules live in `docs/agents/*.yaml`; this file is only a summary.

## Route

- Use `docs/agents/workflows.yaml` for task routing and progress/update rules.
- Use `docs/agents/policy.yaml` for isolation, authority, hard gates, and closeout.
- Use `docs/agents/verify.yaml` for verification profile selection.
- Use `docs/agents/deploy.yaml` before authorized target deployment.
- For deployment, preserve the target's existing Agents layout, track `deployed_file_set`, validate only that set, and report legacy dirty target docs separately.
- Read project memory details only from relevant `docs/memory/index.md` rows.

## Employee Summary

- Assign exact read/write scope first; explorers are read-only, workers need exclusive normalized write scope.
- Use `.agents/runtime/agent-ledger.jsonl` for recovery-sensitive work; use temp roster only as authorized external fallback.
- Runtime close, sidebar/history cleanup, fast hiring, and scoring batch details are canonical in `docs/agents/workflows.yaml`.
- After explicit employee dismissal/cleanup wording, complete the standard finish with authorized Codex App sidebar/history cleanup verification.

## Guardrails

- Project-specific skills stay under `.agents/skills/`.
- Do not intentionally use global/system skills or global Memory for normal work; project-local `.agents/skills/**` is not GS.
- No external filesystem access without exact authorization, except approved temp handoff cache.
- Do not claim hard isolation without current verified evidence.
- Keep deployable templates source-neutral.

## Closeout

Use `docs/agents/policy.yaml` closeout rules. Compact answers should be answer plus the required isolation line only unless a claim needs evidence.
