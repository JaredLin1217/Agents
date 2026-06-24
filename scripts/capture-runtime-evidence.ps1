param(
[Parameter(Mandatory = $true)]
[string] $OutputPath,
[switch] $Full,
[switch] $Quiet
)
$ErrorActionPreference = "Stop"
$RepoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")

function Write-Info {
param([string] $Message)
if (-not $Quiet) {
Write-Host $Message
}
}

function Get-RepoPath {
param([string] $Path)
return Join-Path $RepoRoot $Path
}

function Get-RepoPathHash {
param([string] $Path)
$normalized = [System.IO.Path]::GetFullPath($Path).TrimEnd([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar).ToLowerInvariant()
$bytes = [System.Text.Encoding]::UTF8.GetBytes($normalized)
$sha = [System.Security.Cryptography.SHA256]::Create()
try {
$hash = $sha.ComputeHash($bytes)
return -join ($hash[0..5] | ForEach-Object { $_.ToString("x2") })
}
finally {
$sha.Dispose()
}
}

function Get-EvidenceProjectKey {
$leaf = Split-Path -Leaf $RepoRoot.Path
$safe = ($leaf.ToLowerInvariant() -replace "[^a-z0-9._-]+", "-").Trim("-._")
if ([string]::IsNullOrWhiteSpace($safe)) {
$safe = "agents"
}
return ("{0}-{1}" -f $safe, (Get-RepoPathHash -Path $RepoRoot.Path))
}

function Get-WorkflowVersion {
$text = Get-Content -LiteralPath (Get-RepoPath "docs/agents/version.yaml") -Raw
$match = [regex]::Match($text, '(?m)^\s+version:\s*"([^"]+)"\s*$')
if (-not $match.Success) {
throw "Unable to resolve workflow version."
}
return $match.Groups[1].Value
}

function Get-RepoCommit {
$commit = (& git -C $RepoRoot rev-parse HEAD 2>$null)
if ([string]::IsNullOrWhiteSpace($commit)) {
return "unavailable"
}
return [string] $commit
}

function Get-PowerShellExecutable {
$pwsh = Get-Command pwsh -ErrorAction SilentlyContinue
if ($pwsh) {
return $pwsh.Source
}
return "powershell.exe"
}

function Get-SafeRawOutputRef {
param(
[string] $ProjectKey,
[string] $RunId,
[string] $Name
)
return ("%TEMP%/codex-agent-status/{0}/{1}/{2}.log" -f $ProjectKey, $RunId, $Name)
}

function Invoke-EvidenceCommand {
param(
[string] $Name,
[string] $DisplayCommand,
[string] $ScriptPath,
[string[]] $Arguments,
[string] $RawLogPath,
[string] $RawOutputRef,
[hashtable] $Environment
)
$timer = [System.Diagnostics.Stopwatch]::StartNew()
$previous = @{}
if ($Environment) {
foreach ($entry in $Environment.GetEnumerator()) {
$previous[$entry.Key] = [Environment]::GetEnvironmentVariable($entry.Key, "Process")
[Environment]::SetEnvironmentVariable($entry.Key, [string] $entry.Value, "Process")
}
}
try {
$powerShell = Get-PowerShellExecutable
$processArgs = @("-NoProfile", "-ExecutionPolicy", "Bypass", "-File", $ScriptPath) + $Arguments
$output = & $powerShell @processArgs 2>&1
$exitCode = if ($null -eq $LASTEXITCODE) { 0 } else { [int] $LASTEXITCODE }
}
catch {
$output = @($_.Exception.Message)
$exitCode = 1
}
finally {
if ($Environment) {
foreach ($key in $Environment.Keys) {
[Environment]::SetEnvironmentVariable($key, $previous[$key], "Process")
}
}
$timer.Stop()
}
$outputText = ($output | ForEach-Object { [string] $_ }) -join [Environment]::NewLine
Set-Content -LiteralPath $RawLogPath -Value $outputText -Encoding UTF8
$commandRecord = [ordered]@{
name = $Name
command = $DisplayCommand
result = $(if ($exitCode -eq 0) { "passed" } else { "failed" })
exit_code = $exitCode
duration_ms = [int64] $timer.ElapsedMilliseconds
retry_count = 0
raw_output_ref = $RawOutputRef
}
if ($Name -eq "full_validation") {
$scoreMatch = [regex]::Match($outputText, 'Overall:\s*([0-9.]+)\s*/\s*100')
if ($scoreMatch.Success) {
$commandRecord["overall_score"] = [decimal] $scoreMatch.Groups[1].Value
}
else {
$commandRecord["overall_score"] = $null
}
$commandRecord["evidence_capture_mode"] = "runtime-evidence-bootstrap"
}
return [pscustomobject] $commandRecord
}

$runStarted = (Get-Date).ToUniversalTime()
$workflowVersion = Get-WorkflowVersion
$repoCommit = Get-RepoCommit
$projectKey = Get-EvidenceProjectKey
$runId = ("runtime-evidence-{0}-{1}" -f $runStarted.ToString("yyyyMMddTHHmmssZ"), ([guid]::NewGuid().ToString("N").Substring(0, 8)))
$scratchRoot = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), "codex-agent-status", $projectKey, $runId)
New-Item -ItemType Directory -Path $scratchRoot -Force | Out-Null
$commands = New-Object System.Collections.Generic.List[object]

Push-Location $RepoRoot
try {
$commands.Add((Invoke-EvidenceCommand -Name "deployment_self_test" -DisplayCommand ".\scripts\deploy-agents-workflow.ps1 -SelfTest -Quiet" -ScriptPath (Get-RepoPath "scripts/deploy-agents-workflow.ps1") -Arguments @("-SelfTest", "-Quiet") -RawLogPath (Join-Path $scratchRoot "deployment_self_test.log") -RawOutputRef (Get-SafeRawOutputRef -ProjectKey $projectKey -RunId $runId -Name "deployment_self_test"))) | Out-Null
$commands.Add((Invoke-EvidenceCommand -Name "current_project_dry_run" -DisplayCommand ".\scripts\deploy-agents-workflow.ps1 -TargetPath . -Mode template_provider_mode -LayoutProfile auto -DryRun -Quiet" -ScriptPath (Get-RepoPath "scripts/deploy-agents-workflow.ps1") -Arguments @("-TargetPath", ".", "-Mode", "template_provider_mode", "-LayoutProfile", "auto", "-DryRun", "-Quiet") -RawLogPath (Join-Path $scratchRoot "current_project_dry_run.log") -RawOutputRef (Get-SafeRawOutputRef -ProjectKey $projectKey -RunId $runId -Name "current_project_dry_run"))) | Out-Null
if ($Full) {
$commands.Add((Invoke-EvidenceCommand -Name "full_validation" -DisplayCommand ".\scripts\validate.ps1 -Full -Score" -ScriptPath (Get-RepoPath "scripts/validate.ps1") -Arguments @("-Full", "-Score") -RawLogPath (Join-Path $scratchRoot "full_validation.log") -RawOutputRef (Get-SafeRawOutputRef -ProjectKey $projectKey -RunId $runId -Name "full_validation") -Environment @{ "AGENTS_RUNTIME_EVIDENCE_CAPTURE_ACTIVE" = "1" })) | Out-Null
}
}
finally {
Pop-Location
}

$runFinished = (Get-Date).ToUniversalTime()
$duration = [int64] ($runFinished - $runStarted).TotalMilliseconds
$commandArray = @($commands.ToArray())
$failedCommands = @($commandArray | Where-Object { [string] $_.result -ne "passed" })
$evidence = [ordered]@{
schema_version = "agents-runtime-evidence/v1"
workflow_version = $workflowVersion
repo_commit = $repoCommit
run_started_utc = $runStarted.ToString("o")
run_finished_utc = $runFinished.ToString("o")
duration_ms = $duration
commands = $commandArray
claims = [ordered]@{
static_validation = "Full validation covers repository contracts, schema checks, package checks, and release evidence only."
runtime_evidence = "Self-test and current project dry-run are repeatable local evidence, not live external deployment proof."
hard_isolation = "No hard isolation claim is made without current runtime, tool, OS, account, or cloud enforcement evidence."
}
scope = [ordered]@{
target = "current repository and disposable self-test target"
external_target_deployment = $false
raw_output_storage = "%TEMP%/codex-agent-status/<project-id>/<run-id>/"
}
xr_xw = [ordered]@{
external_reads = @()
external_writes = @("%TEMP%/codex-agent-status/<project-id>/<run-id>/ raw command logs")
}
performance = [ordered]@{
token_usage = "unavailable"
token_usage_reason = "Repository validation scripts do not receive Codex token accounting."
}
result = $(if ($failedCommands.Count -eq 0) { "passed" } else { "failed" })
release = ("v{0}" -f $workflowVersion)
}

if ([System.IO.Path]::IsPathRooted($OutputPath)) {
$resolvedOutputPath = [System.IO.Path]::GetFullPath($OutputPath)
}
else {
$resolvedOutputPath = [System.IO.Path]::GetFullPath((Join-Path (Get-Location) $OutputPath))
}
$outputDir = Split-Path -Parent $resolvedOutputPath
if (-not [string]::IsNullOrWhiteSpace($outputDir)) {
New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
}
$json = ($evidence | ConvertTo-Json -Depth 16) -replace "`r`n", "`n"
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($resolvedOutputPath, ($json + "`n"), $utf8NoBom)
Write-Info ("Runtime evidence written: {0}" -f $OutputPath)
if ($failedCommands.Count -gt 0) {
exit 1
}
