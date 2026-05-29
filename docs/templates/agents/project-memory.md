# Project Memory Overview

This file is the entry point for target-local long-term memory.

It is the project-local substitute for global Codex Memory in normal project work. Keep memory verified, reusable, and specific to this repository.

## Structure

Project memory has two layers:

```text
docs/memory/index.md
docs/memory/entries/
```

- `docs/memory/index.md`: searchable list of memory entries with triggers, keywords, summaries, optional detail links, and verification status.
- `docs/memory/entries/`: optional detailed memory entries with context, cause, fix/rule, verification, and reuse conditions.

## Current Status

- Target-specific memory entries are tracked in `docs/memory/index.md`.
- Global Codex Memory must not be used for normal project work unless the user explicitly asks to use it.
- Add entries only after a task proves the lesson through files, commands, logs, tests, or observed behavior.
- Write project memory index rows and entries in English only.
- The target should add entries only after verified target-local work.

## Add Flow

1. At the end of meaningful work, decide whether a verified reusable lesson exists.
2. Ask the user before adding a project memory entry unless the user explicitly asked to maintain memory.
3. Add a concise index row in `docs/memory/index.md` using the schema in `docs/agents/schemas.yaml`.
4. Set `Entry` to `none` for concise lessons, or add details in `docs/memory/entries/YYYY-MM-DD-short-title.md` when more context is needed.

## Entries

See `docs/memory/index.md`.
