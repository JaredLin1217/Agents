# Workflows

This directory owns GitHub Actions workflows for the Agents workflow checkpoint.

Workflows:

- `checkpoint.yml` runs the fast Agents checkpoint gate on pull requests and pushes
  to `main` or `master`.
- `public-updates.yml` regenerates `docs/github-updates.md` after pushes to
  `main` or `master`, validates the generated document, and commits the update
  back to the pushed branch when the document changed.

Planned workflows:

- `release.yml` for deploy bundle and release checks.

CI should run only checks that already pass locally. Do not add placeholder
workflows that claim coverage before the corresponding local command exists.

The checkpoint gate currently runs:

- `.\scripts\validate.ps1`

The public update workflow currently runs:

- `.\scripts\update-github-updates.ps1`
- `.\scripts\validate.ps1 -Quiet`
- `.\scripts\commit-github-updates.ps1`

Run `.\scripts\validate.ps1 -Full` and `git diff --check` locally for release
or full-audit validation.
