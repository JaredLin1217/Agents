# Contributing

Inspect existing changes before editing. Keep each task scoped and preserve user
work. Durable rules, docs, skills, schemas, and templates are English-only.
Use standard JSON for project-owned machine contracts; do not mirror prose into
schemas or add another scheduling abstraction over native Codex capabilities.

Run `scripts/validate.ps1 -Scope Provider -Profile Changed` during iteration and
`-Profile Checkpoint` before committing. Consumer validation checks only managed
files and explicit project test wrappers; it is not proof of product correctness.
Use actual test results and artifact checks, never agent self-scores.

Deployable changes must update the explicit deployment catalog and regression
tests together. Do not stage `.agents/runtime/`, local Codex configuration,
credentials, private target data, generated packages, or raw model event logs.
Keep root rules concise and load conditional workflows progressively. Byte counts
are observations, not arbitrary release limits. Register generated artifacts in
runtime; do not leave adjacent JSON staging files or silently delete failed tests.

Describe changed behavior, tests run, known gaps, and ownership implications in
pull requests. Source changes are committed before release evidence capture;
the subsequent evidence commit may change only the declared evidence file.
