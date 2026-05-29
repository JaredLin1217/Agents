# Codex Memory Layout

Canonical memory policy: `docs/agents/workflows.yaml`.

This project uses repository-local memory only. Do not use Codex global Memory unless the user explicitly asks to re-enable it.

## What Goes Where

- Every-session rule: `AGENTS.md`
- Canonical compact workflow rule: `docs/agents/*.yaml`
- Verified reusable project lesson: `docs/memory/index.md` plus optional `docs/memory/entries/`
- Durable reason or tradeoff: `docs/decisions/`
- Repeatable procedure: `docs/agents/workflows.yaml`, a short runbook stub, or a project-local skill
- Formal project docs: `docs/`

## Add Flow

1. Confirm the lesson is verified, project-specific, and likely to recur.
2. Prefer current repo evidence over prior chat or memory.
3. Add an index row in `docs/memory/index.md` using the schema in `docs/agents/schemas.yaml`.
4. Set `Entry` to `none` for concise lessons, or start from `docs/memory-entry.template.md` and add details in `docs/memory/entries/` when more context is needed.
5. Do not treat memory triggers as routine verification gates; recurring gates belong in `docs/agents/verify.yaml`.
6. Do not write to global Memory without explicit user approval.

## Draft Fields

Use the `memory_entry` schema in `docs/agents/schemas.yaml`: Trigger, Context, Cause, Fix / Rule, Verification, Reuse when.
