# Task Closeout

Use at the end of non-trivial project work.

1. Select the smallest verification profile from `docs/agents/verify.yaml` that proves the current claim.
2. Run or report the closest practical verification for that profile.
3. Inspect `git status -sb --ignored --untracked-files=all`.
4. Report changed files and why they changed.
5. Report verification commands and results.
6. Report remaining risk or skipped checks.
7. Report project-local skills used separately from Global Skill usage.
8. Report system/global resources outside Global Memory or Global Skills when used.
9. Do not rerun or relist resolved one-off literal checks as routine gates.
10. State whether new durable knowledge should become a rule, decision, memory entry, runbook, or skill.
11. State the verified claim scope from `docs/agents/verify.yaml`: static policy pack, runtime multi-agent, hard isolation, or not claimed.
12. Include the required isolation line.

Use `not claimed` when no claim scope has current evidence.
Do not claim no deduction items unless every required proof in `docs/agents/verify.yaml` is satisfied.
Do not run release-grade gates for ordinary closeout unless the task is commit, tag, release, deploy, push, or no-deduction validation.
Do not report static policy-pack verification as runtime employee validation or hard isolation.
