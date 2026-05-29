# Task Closeout

Use the smallest closeout that proves the current claim.

1. Pick the smallest `docs/agents/verify.yaml` profile.
2. Answer-only with no current repo-state claim: run no command and use compact closeout.
3. Policy-pack edits: check changed files and changed mirror pairs only unless making a broader claim.
4. Inspect git status only when files changed, current repo state is claimed, or git/release/deploy actions are involved.
5. Expand the report only for file changes, verification, risk, external access, durable knowledge, or explicit claim scope.
6. Do not rerun resolved one-off literal checks.
7. Always include:

```text
Isolation: GM <used/not used> | GS <used/not used> | XR <none/paths> | XW <none/paths>
```

Full release-grade gates are only for commit/tag/release/deploy/push/broad audit/no-deduction claims. Do not present static checks as runtime or hard-isolation proof.
