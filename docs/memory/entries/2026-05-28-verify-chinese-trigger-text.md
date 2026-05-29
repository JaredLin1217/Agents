# Use English Trigger Rules With Semantic Matching

- Trigger: Updating employee hiring trigger rules or examples.
- Context/Cause: Durable trigger rules must not store user-language literals; they also risk terminal encoding issues.
- Fix / Rule: Keep rules English and source-neutral. Runtime can treat clear hire/spawn/delegate/parallel-agent equivalents as explicit requests.
- Verification: `docs/agents/workflows.yaml`, `AGENTS.md`, and the project skill use semantic matching without user-language trigger literals.
- Reuse when: Updating multi-agent triggers, templates, assignments, or command examples.
