# Use ASCII Employee Trigger Aliases

- Trigger: Terminal output shows mojibake around employee hiring trigger rules.
- Context: Multi-agent trigger text included non-ASCII user-facing wording.
- Cause: Some terminals render non-ASCII trigger phrases inconsistently.
- Fix / Rule: Keep project rules in English and use ASCII aliases such as `hire employee` and `spawn employee`.
- Verification: Repo rules and templates use English-only wording for persistent rules.
- Reuse when: Updating multi-agent triggers, templates, or command examples.
