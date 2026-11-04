# Agents Governance plugin

This local-first plugin packages the Agents v5 planning, checkpoint, memory,
runtime and migration skills. The v4 migration schema is bundled under
`migrations/v4` so an extracted plugin can perform its dry-run and guarded
upgrade without reaching back into the source repository. It contains no MCP
server, telemetry, secret, transcript or lifecycle hook. Hooks remain a
separate opt-in template and need native trust review.

The packaged scripts require PowerShell 7.4 or newer and Git. Run the onboarding
skill or `scripts/agents.ps1 doctor` before changing a Consumer.
