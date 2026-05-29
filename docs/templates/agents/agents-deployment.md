# Agents Deployment

Use when copying this Agents workflow into another explicitly authorized repository.

1. Confirm exact target path and write action.
2. Read `docs/agents/deploy.yaml`.
3. Inspect target repository state before writing.
4. Copy or adapt only allowlisted files.
5. Use target starters for memory, memory index, and project structure.
6. Do not copy source status, memory rows, employee history, commits, remotes, validation history, `.codex/config.toml`, `.codex/environments/environment.toml`, `.git/`, or temp cache state.
7. Validate source-neutral templates and target git state.

References: `docs/agents/deploy.yaml`, `docs/agents/verify.yaml`.
