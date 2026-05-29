# Use English Trigger Rules With Semantic Matching

- Trigger: Updating employee hiring trigger rules or examples.
- Context: Durable multi-agent trigger rules previously risked mixing user-facing non-English phrases with repository rules.
- Cause: Some terminals render non-ASCII trigger phrases inconsistently.
- Fix / Rule: Keep durable project rules in English and source-neutral. A clear natural-language equivalent of hire, spawn, delegate, or parallel-agent may count as explicit at runtime, but user-language trigger literals must not become routine verification gates.
- Verification: `docs/agents/workflows.yaml`, `AGENTS.md`, and `.agents/skills/project-isolation-workflow/SKILL.md` route clear semantic equivalents without storing user-language trigger literals.
- Reuse when: Updating multi-agent triggers, templates, assignment prompts, or command examples.
