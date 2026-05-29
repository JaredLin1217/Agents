# Agents Deployment

Use when copying this Agents workflow into another explicitly authorized repository.

1. Confirm exact target path and write action.
2. Read `docs/agents/deploy.yaml`.
3. Inspect target repository state before writing.
4. Copy or adapt only allowlisted files.
5. Use template starters for target project memory, memory index, and project structure; do not copy source versions.
6. Treat source `README.md`, `docs/decisions/`, `docs/memory/entries/`, `.gitattributes`, and `.codex/environments/environment.template.toml` as target-owned or case-by-case after inspection.
7. Never copy source status, memory rows, employee history, commits, remotes, validation history, `.codex/config.toml`, `.codex/environments/environment.toml`, `.git/`, or live temp cache state.
8. Validate source-neutral templates and target git state.

Key references:

- Deployment allowlist and gates: `docs/agents/deploy.yaml`
- Verification gates: `docs/agents/verify.yaml`
