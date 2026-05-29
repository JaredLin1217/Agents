# Decision 0001: Project-Isolated Knowledge

## Decision

This project keeps Codex working knowledge inside the repository instead of using global Codex Memory.

## Reason

The project is intended to stay isolated from other workspaces. Global Memory can contain lessons from unrelated projects, which may leak old assumptions into new work. Repo-local rules and docs make project behavior auditable and portable.

## Rules

- Keep every-session rules in `AGENTS.md`.
- Keep project memory intake rules in `docs/codex-memory.md`.
- Keep project memory overview in `docs/project-memory.md`.
- Keep project memory index in `docs/memory/index.md`.
- Keep detailed project memory entries in `docs/memory/entries/`.
- Keep repeatable workflow SOPs in `docs/runbooks/` or `.agents/skills/`.
- Keep durable architecture/product/process decisions in `docs/decisions/`.
- Do not write to global Codex Memory unless the user explicitly asks to re-enable or use it.
- Treat Codex system skills, plugins, and global instructions as runtime capabilities, not as project knowledge stores.
- Do not intentionally use global/system skills for normal project work unless the user explicitly requests that capability or a higher-priority runtime instruction requires it.
- If a system/global capability is used, keep project-specific results in this repository and report the usage.
- For normal project work, project-external filesystem access is not allowed. Any exception requires explicit user authorization for the exact path and action.
- Every assistant reply in this repository must report global Memory usage, global Skill usage, project-external reads, and project-external writes.
- Use `docs/runbooks/isolation-audit.md` as the operational checklist for this decision.

## Consequences

- New sessions must rely on repo files for project context.
- Useful lessons should be written as `docs/memory/index.md` plus `docs/memory/entries/`, repo docs, decisions, or project-local skills.
- The project can be moved or shared without depending on `C:\Users\v_jar\.codex\memories\`.
- This decision cannot technically disable Codex runtime capabilities by itself; it defines the project boundary and reporting rule.
- Closeout reports may be slightly longer, but they make isolation auditable.
