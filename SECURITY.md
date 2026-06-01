# Security Policy

## Supported Scope

Security reports for this repository should focus on:

- accidental deployment of secrets, runtime state, or local Codex configuration
- unsafe deployment-script behavior
- validation gaps that allow source-specific data into deployable templates
- documentation that could cause unsafe handling of credentials or private target
  repositories

This repository is not a hosted service. Security impact is primarily about
repository content, deployment behavior, and local workflow safety.

## Reporting

Do not open public issues containing secrets, credentials, private target paths,
or private repository content.

Preferred reporting path:

1. Use GitHub private vulnerability reporting if it is enabled for the
   repository.
2. If private reporting is unavailable, open a minimal public issue that states
   a security concern exists and asks the maintainer for a private contact path.
   Do not include sensitive details in that issue.

## Handling Sensitive Files

The project intentionally treats these as local-only or protected:

- `.agents/runtime/`
- `.codex/config.toml`
- `.codex/environments/environment.toml`
- secrets, credentials, and deployment evidence
- target-owned app code and Git metadata

If any of these appear in a proposed deployment, commit, issue, or pull request,
stop and remove the sensitive material before continuing.
