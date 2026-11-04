# Agents Governance plugin

This local-first plugin packages the Agents v5 planning, checkpoint, memory,
runtime and migration skills. It contains no MCP server, telemetry, secret,
transcript or lifecycle hook. Hooks remain a separate opt-in template and need
native trust review.

The packaged scripts require PowerShell 7.4 or newer and Git. Run the onboarding
skill or `scripts/agents.ps1 doctor` before changing a Consumer.
