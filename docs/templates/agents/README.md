# Agents Templates

Source-neutral starter bundle for deploying this Agents workflow into an explicitly authorized target repository.

## Files

- `AGENTS.md`: compact project rule router.
- `agents/*.yaml`: canonical policy pack.
- `skills/project-isolation-workflow/`: project-local skill and metadata.
- `agent-*.template.md`, `controller-lease.template.md`, `hard-isolation-evidence.template.md`, `runtime-multi-agent-validation.template.md`: runtime and evidence schemas.
- `codex-memory.md`, `project-memory.md`, `memory-index.md`, `memory-entry.template.md`, `memory-entries-README.md`: target-local memory starters.
- `*-workflow.md`, `*-handoff.md`, `*-audit.md`, `*-deployment.md`, `*-maintenance.md`, `*-authoring.md`, `task-closeout.md`: short runbook routers.
- `gitignore.fragment`: local runtime and scratch ignore patterns.

## Use

Follow `docs/agents/deploy.yaml`. Copy only allowlisted files, adapt to the target after inspection, and keep target-specific status, memory, commits, remotes, and deployment history inside the target repository.
