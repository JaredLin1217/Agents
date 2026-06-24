function Test-ReleasePackageExport {
$startFailureCount = $Failures.Count
$validationRoot = Get-ValidationTempRoot -Purpose "release-export-validation"
$previousErrorActionPreference = $ErrorActionPreference
$ErrorActionPreference = "Continue"
try {
$output = & (Get-RepoPath "scripts/export-release-package.ps1") -OutputPath $validationRoot -Quiet 2>&1
$exitCode = if ($null -eq $LASTEXITCODE) { 0 } else { $LASTEXITCODE }
}
finally {
$ErrorActionPreference = $previousErrorActionPreference
}
if ($exitCode -ne 0) {
Add-Failure "Release package export failed."
foreach ($line in $output) {
Add-Failure ("Release package export detail: {0}" -f $line)
}
return
}
if (@($output).Count -gt 0) {
Add-Failure "Release package export quiet mode produced output."
foreach ($line in $output) {
Add-Failure ("Release package export quiet output: {0}" -f $line)
}
}
$versionValues = Get-LightweightYamlPathValues -File (Get-Item -LiteralPath (Get-RepoPath "docs/agents/version.yaml"))
$version = [string] $versionValues["workflow.version"]
$packageRoot = Join-Path $validationRoot ("jared-ai-team-v{0}" -f $version)
$manifestPath = Join-Path $packageRoot "release-manifest.json"
if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) {
Add-Failure "Release package manifest is missing."
return
}
try {
$manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
}
catch {
Add-Failure "Release package manifest is not valid JSON."
return
}
if ([string] $manifest.version -ne $version) {
Add-Failure ("Release package manifest version mismatch. Expected {0}; found {1}." -f $version, $manifest.version)
}
if ([string]::IsNullOrWhiteSpace([string] $manifest.package_hash)) {
Add-Failure "Release package manifest package_hash is empty."
}
if ([int] $manifest.file_count -le 0) {
Add-Failure "Release package manifest file_count must be positive."
}
if ($null -eq $manifest.PSObject.Properties["blocklist_result"]) {
Add-Failure "Release package manifest blocklist_result is missing."
}
else {
if (-not [bool] $manifest.blocklist_result.checked) {
Add-Failure "Release package manifest blocklist_result.checked must be true."
}
$policy = @($manifest.blocklist_result.policy | ForEach-Object { [string] $_ })
foreach ($requiredPolicy in @(".agents/runtime/**", ".workflow/**", ".agents/runtime/agent-ledger.jsonl", ".codex/config.toml", "API keys", "provider sessions")) {
if ($policy -notcontains $requiredPolicy) {
Add-Failure ("Release package manifest blocklist policy is missing: {0}" -f $requiredPolicy)
}
}
}
$requiredFiles = @(
"docs/agents/org.yaml",
"docs/agents/model-policy.yaml",
"docs/agents/dispatch.yaml",
"docs/agents/workflow-artifacts.yaml",
"docs/agents/context-compact.yaml",
"docs/agents/collaborators.yaml",
"docs/agents/core-system.yaml",
"docs/agents/runtime-execution.yaml",
"docs/agents/provider-adapters.yaml",
"docs/agents/route-packs.yaml",
"docs/agents/knowledge-footprint.yaml",
"docs/agents/openai-foundations.yaml"
)
$manifestPaths = @($manifest.files | ForEach-Object { [string] $_.path })
foreach ($requiredFile in $requiredFiles) {
if ($manifestPaths -notcontains $requiredFile) {
Add-Failure ("Release package is missing required file: {0}" -f $requiredFile)
}
if (-not (Test-Path -LiteralPath (Join-Path $packageRoot ($requiredFile -replace "/", [System.IO.Path]::DirectorySeparatorChar)) -PathType Leaf)) {
Add-Failure ("Release package physical file is missing: {0}" -f $requiredFile)
}
}
$blockedExact = @(
".codex/config.toml",
".codex/environments/environment.toml",
".codex/environments/environment.template.toml",
".agents/runtime/collaborators.jsonl",
".agents/runtime/agent-ledger.jsonl",
"docs/agent-status.md",
".agents/docs/agent-status.md"
)
$blockedPrefix = @(
".git/",
".codex/environments/",
".agents/runtime/",
".agents/runtime/workflows/",
".workflow/",
"docs/agent-events/",
".agents/docs/agent-events/",
"docs/tmp-approval-",
".agents/docs/tmp-approval-",
"docs/hard-isolation-evidence/",
".agents/docs/hard-isolation-evidence/",
"docs/runtime-multi-agent-validation/",
".agents/docs/runtime-multi-agent-validation/"
)
foreach ($path in $manifestPaths) {
$rel = $path.ToLowerInvariant()
if ($blockedExact -contains $rel) {
Add-Failure ("Release package manifest includes blocked local path: {0}" -f $path)
}
foreach ($prefix in $blockedPrefix) {
if ($rel.StartsWith($prefix)) {
Add-Failure ("Release package manifest includes blocked local path: {0}" -f $path)
}
}
}
$blockedPhysical = @(
".git",
".agents/runtime",
".agents/runtime/workflows",
".agents/runtime/executions",
".agents/runtime/knowledge",
".agents/runtime/route-packs",
".agents/runtime/tool-evidence",
".agents/runtime/deployments",
".workflow",
".codex/config.toml",
".codex/environments/environment.toml",
".codex/environments",
".agents/runtime/collaborators.jsonl",
".agents/runtime/agent-ledger.jsonl"
)
foreach ($blocked in $blockedPhysical) {
$fullPath = Join-Path $packageRoot ($blocked -replace "/", [System.IO.Path]::DirectorySeparatorChar)
if (Test-Path -LiteralPath $fullPath) {
Add-Failure ("Release package contains blocked local path: {0}" -f $blocked)
}
}
if ($Failures.Count -eq $startFailureCount) {
Add-Pass "Release package export checks passed."
}
}

function Test-ObjectField {
param(
[object] $Object,
[string] $Field,
[string] $Context
)
if ($null -eq $Object -or $null -eq $Object.PSObject.Properties[$Field]) {
Add-Failure ("{0} is missing required field: {1}" -f $Context, $Field)
return $false
}
return $true
}

function Test-RuntimeReleaseEvidence {
if ($env:AGENTS_RUNTIME_EVIDENCE_CAPTURE_ACTIVE -eq "1") {
Add-Pass "Runtime release evidence check deferred during evidence capture."
return
}
$startFailureCount = $Failures.Count
$schemaPath = Get-RepoPath "schemas/agents-runtime-evidence.schema.json"
$evidencePath = Get-RepoPath "docs/evidence/releases/v2.6.2-runtime-evidence.json"
foreach ($path in @($schemaPath, $evidencePath)) {
if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
Add-Failure ("Runtime release evidence file is missing: {0}" -f $path)
}
}
if ($Failures.Count -ne $startFailureCount) {
return
}
try {
$schema = Get-Content -LiteralPath $schemaPath -Raw | ConvertFrom-Json
$evidence = Get-Content -LiteralPath $evidencePath -Raw | ConvertFrom-Json
}
catch {
Add-Failure ("Runtime release evidence JSON parse failed: {0}" -f $_.Exception.Message)
return
}
$requiredFields = @("schema_version", "workflow_version", "repo_commit", "run_started_utc", "run_finished_utc", "duration_ms", "commands", "claims", "scope", "xr_xw")
$schemaRequired = @($schema.required | ForEach-Object { [string] $_ })
foreach ($field in $requiredFields) {
if ($schemaRequired -notcontains $field) {
Add-Failure ("Runtime evidence schema is missing required field contract: {0}" -f $field)
}
[void] (Test-ObjectField -Object $evidence -Field $field -Context "Runtime evidence")
}
if ([string] $evidence.schema_version -ne "agents-runtime-evidence/v1") {
Add-Failure "Runtime evidence schema_version mismatch."
}
$expectedVersion = Get-CanonicalWorkflowVersion
if ([string] $evidence.workflow_version -ne $expectedVersion) {
Add-Failure ("Runtime evidence workflow_version must be {0}." -f $expectedVersion)
}
if ([string]::IsNullOrWhiteSpace([string] $evidence.repo_commit)) {
Add-Failure "Runtime evidence repo_commit is empty."
}
try {
$started = [datetimeoffset]::Parse([string] $evidence.run_started_utc)
$finished = [datetimeoffset]::Parse([string] $evidence.run_finished_utc)
if ($finished -lt $started) {
Add-Failure "Runtime evidence finish time is earlier than start time."
}
}
catch {
Add-Failure "Runtime evidence timestamps must be ISO date-time values."
}
if ([int64] $evidence.duration_ms -lt 0) {
Add-Failure "Runtime evidence duration_ms must be non-negative."
}
$commands = @($evidence.commands)
$requiredCommandNames = @("deployment_self_test", "current_project_dry_run", "full_validation")
foreach ($name in $requiredCommandNames) {
if (@($commands | Where-Object { [string] $_.name -eq $name }).Count -ne 1) {
Add-Failure ("Runtime evidence must contain exactly one command: {0}" -f $name)
}
}
foreach ($command in $commands) {
foreach ($field in @("name", "command", "result", "exit_code", "duration_ms", "retry_count", "raw_output_ref")) {
[void] (Test-ObjectField -Object $command -Field $field -Context ("Runtime evidence command {0}" -f $command.name))
}
if ([string] $command.result -ne "passed") {
Add-Failure ("Runtime evidence command did not pass: {0}" -f $command.name)
}
if ([int] $command.exit_code -ne 0) {
Add-Failure ("Runtime evidence command exit_code must be 0: {0}" -f $command.name)
}
if ([int64] $command.duration_ms -lt 0) {
Add-Failure ("Runtime evidence command duration_ms must be non-negative: {0}" -f $command.name)
}
if ([int] $command.retry_count -lt 0) {
Add-Failure ("Runtime evidence command retry_count must be non-negative: {0}" -f $command.name)
}
$rawRef = [string] $command.raw_output_ref
if (-not $rawRef.StartsWith("%TEMP%/codex-agent-status/")) {
Add-Failure ("Runtime evidence raw output reference must stay in status scratch: {0}" -f $command.name)
}
if ($rawRef -match '^[A-Za-z]:\\' -or $rawRef.Contains("\")) {
Add-Failure ("Runtime evidence raw output reference must not expose an absolute or platform path: {0}" -f $command.name)
}
if ([string] $command.name -eq "full_validation") {
if ($null -eq $command.PSObject.Properties["overall_score"] -or [decimal] $command.overall_score -ne [decimal] 100.0) {
Add-Failure "Runtime evidence full_validation must record overall_score 100.0."
}
}
}
foreach ($field in @("static_validation", "runtime_evidence", "hard_isolation")) {
[void] (Test-ObjectField -Object $evidence.claims -Field $field -Context "Runtime evidence claims")
}
foreach ($field in @("target", "external_target_deployment", "raw_output_storage")) {
[void] (Test-ObjectField -Object $evidence.scope -Field $field -Context "Runtime evidence scope")
}
if ([bool] $evidence.scope.external_target_deployment) {
Add-Failure "Runtime evidence must not claim external target deployment."
}
foreach ($field in @("external_reads", "external_writes")) {
[void] (Test-ObjectField -Object $evidence.xr_xw -Field $field -Context "Runtime evidence xr_xw")
}
if (@($evidence.xr_xw.external_reads).Count -ne 0) {
Add-Failure "Runtime evidence must not record external reads for this release."
}
if ($null -eq $evidence.PSObject.Properties["performance"]) {
Add-Failure "Runtime evidence must include performance baseline details."
}
else {
if ([string] $evidence.performance.token_usage -ne "unavailable") {
Add-Failure "Runtime evidence token usage must be marked unavailable when metrics are absent."
}
if ([string]::IsNullOrWhiteSpace([string] $evidence.performance.token_usage_reason)) {
Add-Failure "Runtime evidence token usage reason is required."
}
}
$serialized = $evidence | ConvertTo-Json -Depth 16 -Compress
foreach ($forbidden in @($RepoRoot.Path, "C:\Users\", "D:\", "JaredLin")) {
if (-not [string]::IsNullOrWhiteSpace($forbidden) -and $serialized.Contains($forbidden)) {
Add-Failure ("Runtime evidence leaks a local absolute/source-specific path marker: {0}" -f $forbidden)
}
}
if ($Failures.Count -eq $startFailureCount) {
Add-Pass "Runtime release evidence checks passed."
}
}
