# Workflows

This directory owns GitHub Actions workflows for the Agents workflow checkpoint.

Workflows:

- `checkpoint.yml` runs the full Agents workflow gate on pull requests and pushes
  to `main` or `master`.

Planned workflows:

- `release.yml` for deploy bundle and release checks.

CI should run only checks that already pass locally. Do not add placeholder
workflows that claim coverage before the corresponding local command exists.

The checkpoint gate currently runs:

- `.\scripts\validate.ps1 -Full`
- `git diff --check`
