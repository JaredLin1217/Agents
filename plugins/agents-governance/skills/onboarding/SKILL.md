---
name: agents-governance-onboarding
description: Set up and inspect the Agents v5 governance package for a project without changing business files.
---

# Agents governance onboarding

Run `scripts/agents.ps1 doctor` and `scripts/agents.ps1 plan` first. Explain the
root or dot-agents layout, local-only memory/runtime boundary, explicit v4
migration, and the Changed versus Checkpoint validation cadence. Never enable
hooks, promote knowledge, deploy files or clean runtime without an explicit user
request and a reviewed plan.