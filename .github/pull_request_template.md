## Summary

- Describe the user-facing change and any deployment impact.

## Validation

- [ ] `.\scripts\validate.ps1`
- [ ] `git diff --check`
- [ ] `.\scripts\validate.ps1 -Full` when deployment, release, schema, or broad policy behavior changed

## Deployment Impact

- [ ] No deployment behavior changed
- [ ] Deployment behavior changed and `docs/agents/deploy.yaml` was reviewed
- [ ] Templates remain source-neutral

## Runtime / Local State

- [ ] No `.agents/runtime/`, `.codex/`, secrets, generated output, or target-owned local state is staged
