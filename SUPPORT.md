# Support

This repository is a workflow provider for project-local Agents rules,
validation, deployment templates, and Codex operating procedures.

## Good Support Requests

Open an issue when you have:

- a reproducible validation failure
- a deployment dry-run or upgrade failure
- a source-neutrality or template drift concern
- a schema contract issue
- documentation that is unclear or missing

Include the relevant command, exit status, sanitized output, operating system,
PowerShell version, and the specific file paths involved.

## Keep Private Data Out

Do not include:

- secrets or credentials
- private target repository content
- `.codex/config.toml`
- `.codex/environments/environment.toml`
- `.agents/runtime/` contents
- private deployment evidence
- proprietary target app code

If a problem requires private evidence, provide a minimal sanitized reproduction
or describe the failure without exposing sensitive content.
