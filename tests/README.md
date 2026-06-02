# Tests
This directory owns fixtures and automated tests for the Agents governance rules.
Initial scope:
- Positive and negative YAML fixtures.
- Schema contract tests.
- Validation-script regression cases.
- Deploy/source-boundary fixtures.
Tests should avoid live runtime state, external services, and user-specific
machine paths unless a fixture explicitly models those paths as inert strings.