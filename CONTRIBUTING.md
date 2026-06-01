# Contributing

Thank you for improving this Agents workflow provider. Contributions should
preserve the repository's core contract: deployable workflow files must stay
source-neutral, validation must remain reproducible, and local runtime state must
not be committed.

## Local Workflow

1. Start from a clean understanding of the working tree:

   ```powershell
   git status -sb --ignored --untracked-files=all
   ```

2. Make focused changes.
3. Run the fast validation gate:

   ```powershell
   .\scripts\validate.ps1
   ```

4. For deployment, release, schema, or broad policy changes, run:

   ```powershell
   .\scripts\validate.ps1 -Full
   ```

5. Check whitespace before committing:

   ```powershell
   git diff --check
   ```

## Durable Documentation Rules

- Keep durable rules, templates, runbooks, and schemas in English.
- Keep `docs/agents/*.yaml` as the canonical source for behavior.
- Keep deployable template mirrors synchronized with source rules.
- Do not add project-specific target paths, usernames, remotes, commit hashes, or
  session history to deployable templates.

## Do Not Commit

Do not stage or commit:

- `.agents/runtime/`
- `.codex/config.toml`
- `.codex/environments/environment.toml`
- secrets or credentials
- target deployment history
- generated output, caches, build output, or vendored files unless explicitly
  adopted by the project

## Pull Requests

Pull requests should describe:

- what changed
- why it changed
- which validation commands passed
- whether deployment behavior changed
- whether any target-owned or local-only state was intentionally left untouched

Use the smallest validation profile that proves the claim. Do not claim hard
isolation, runtime multi-agent behavior, deployment success, or release readiness
without current evidence.
