## Summary
- Describe the user-facing change and any deployment impact.
## Validation
- [ ] `.\scripts\validate.ps1 -Scope Provider -Profile Checkpoint`
- [ ] `git diff --check`
- [ ] Report actual checks and unresolved acceptance gaps; do not substitute a score
## Deployment Impact
- [ ] No deployment behavior changed
- [ ] Deployment behavior changed and `docs/agents/deployment.json` was reviewed
- [ ] Owned paths preserve target knowledge, product files and local settings
## Runtime / Local State
- [ ] No `.agents/runtime/`, `.codex/`, secrets, generated output, or target-owned local state is staged
