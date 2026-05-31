# MCP

This directory owns project-level Model Context Protocol capability boundaries.

Initial scope:

- A registry that describes MCP servers before implementation.
- Read/write classification for each tool.
- Approval policy and external access classification.
- Verification commands for each registered capability.

The first registry version should prefer read-only capabilities. Write-capable
tools require explicit approval policy, scope, and audit expectations before
they are enabled.
