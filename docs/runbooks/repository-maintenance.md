# Repository Maintenance

Use when cleaning, slimming, validating, or restructuring this Agents repository.

1. Inspect `git status -sb --ignored --untracked-files=all`.
2. Keep `AGENTS.md` compact; move detail to `docs/agents/*.yaml`.
3. Keep project-local skills concise.
4. Keep deployable templates source-neutral and aligned with source rules.
5. Keep live runtime status, temp events, local Codex environment, caches, generated output, and filled evidence records out of commits unless explicitly targeted and reviewed.
6. Use the smallest verification profile from `docs/agents/verify.yaml` that proves the current claim.
7. Before commit, tag, release, deploy, or push claims, stage/track non-ignored policy/template files intended for the change or report them as intentionally excluded.
8. Before commit, tag, release, deploy, or push claims, resolve line-ending warnings and `w/crlf` or `w/mixed` states for files governed by `eol=lf`, or report them against `.gitattributes`.
9. Run release-grade verification only for commit, tag, release, deploy, push, or no-deduction claims.

Key references:

- Maintenance rules: `docs/agents/workflows.yaml`
- Verification gates: `docs/agents/verify.yaml`
