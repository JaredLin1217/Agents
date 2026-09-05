#requires -Version 7.0
param([string]$OutputPath='docs/evidence/releases/v3.0.0-runtime-evidence.json')
. "$PSScriptRoot/agent-checks.ps1"
$root=Get-AgentRoot
$expected=(Read-AgentJson (Join-Path $root 'agents.json')).release_evidence
if($OutputPath.Replace('\','/').TrimStart('./') -ne $expected) { throw 'Only the declared release evidence path may be excluded.' }
$destination=Resolve-SafePath $root $expected
$status=@(Invoke-AgentGit $root @('status','--porcelain'))
if($status.Count) { throw 'Commit source changes before capturing evidence.' }
$source=[string](Invoke-AgentGit $root @('rev-parse','HEAD'))
$files=@(Get-AgentFiles $root|Where-Object { $_ -ne $expected })
$digest=Get-SourceDigest $root $files
$timer=[Diagnostics.Stopwatch]::StartNew()
$report=Invoke-AgentChecks -Root $root -Scope Provider -Profile Checkpoint
$timer.Stop()
if($digest -ne (Get-SourceDigest $root @(Get-AgentFiles $root|Where-Object { $_ -ne $expected })) -or
    @(Invoke-AgentGit $root @('status','--porcelain')).Count -or $source -ne [string](Invoke-AgentGit $root @('rev-parse','HEAD'))) {
    throw 'Source changed during evidence capture.'
}
$evidence=[ordered]@{schema_version='agents-runtime-evidence/v5';workflow_version='3.0.0';source_commit=$source;
    validated_content_digest=$digest;excluded_paths=@($expected);run_started_utc=$report.started_utc;run_finished_utc=$report.finished_utc;
    working_tree_status_at_capture='clean';duration_ms=$timer.ElapsedMilliseconds;host=$report.host;commands=$report.checks;
    result=$(if($report.passed){'passed'}else{'failed'});scope='Provider and disposable local targets only';
    claims=@('Offline regression evidence; not model task accuracy or an external project pilot.','No hard isolation claim. Behavioral boundaries and file ownership checks only.');
    token_usage=@{status='unavailable';reason='Offline checks do not invoke a model. Real model usage is reported separately by the A/B evaluator.'}}
# Raw failures can contain local paths; keep those details in ignored state only.
Write-AgentJson (Resolve-SafePath $root '.agents/runtime/checkpoint-last.json') $report
foreach($receipt in $evidence.commands) {
    $receipt.details=@($receipt.details|ForEach-Object { $_.Replace($root,'<repo>') })
}
if(-not(Test-Json -Json ($evidence|ConvertTo-Json -Depth 30) -SchemaFile (Join-Path $root 'schemas/release-evidence.schema.json'))) { throw 'Invalid evidence.' }
Write-AgentJson $destination $evidence
"Evidence: $expected; result=$($evidence.result); source=$source"
if(-not $report.passed) { exit 1 }
