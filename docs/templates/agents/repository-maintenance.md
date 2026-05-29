# Repository Maintenance

Use when cleaning, slimming, validating, or restructuring this Agents repository.

1. Inspect `git status -sb --ignored --untracked-files=all`.
2. Keep `AGENTS.md` compact; move detail to `docs/agents/*.yaml`.
3. Keep project-local skills concise.
4. Keep deployable templates source-neutral and aligned with source rules.
5. Keep live runtime status, temp events, local Codex environment, caches, generated output, and filled evidence records out of commits unless explicitly targeted and reviewed.
6. Before commit, tag, release, deploy, or push claims, stage/track non-ignored policy/template files intended for the change or report them as intentionally excluded.
7. Before commit, tag, release, deploy, or push claims, resolve line-ending warnings and `w/crlf` or `w/mixed` states for files governed by `eol=lf`, or report them against `.gitattributes`.
8. Run no-script verification from `docs/agents/verify.yaml`.

Key references:

- Maintenance rules: `docs/agents/workflows.yaml`
- Verification gates: `docs/agents/verify.yaml`
