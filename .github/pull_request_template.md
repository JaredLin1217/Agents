## Summary
- Describe the user-facing change and any deployment impact.
## Validation
- [ ] `pwsh -NoProfile -File scripts/agents.ps1 plan -Json`
- [ ] `pwsh -NoProfile -File scripts/agents.ps1 validate checkpoint -Json` (delivery boundary)
- [ ] `git diff --check`
- [ ] Report actual checks and unresolved acceptance gaps; do not substitute a score
## Deployment Impact
- [ ] No deployment behavior changed
- [ ] Deployment behavior changed and `docs/agents/deployment.json` was reviewed
- [ ] Owned paths preserve target knowledge, product files and local settings
## Runtime / Local State
- [ ] No `.agents/runtime/`, `.codex/`, secrets, generated output, or target-owned local state is staged
