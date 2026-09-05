#requires -Version 7.0
param([Parameter(Mandatory)][string]$CodexPath,[Parameter(Mandatory)][string]$CandidateCommit,
      [string]$BaselineCommit='5e1643410233858ed70e4567beb01468fe0c2dc8',
      [ValidateRange(1,3)][int]$Repetitions=3,[ValidateRange(30,1800)][int]$TimeoutSeconds=600,
      [string[]]$Case=@())
. "$PSScriptRoot/fixture.ps1"
. "$PSScriptRoot/metrics.ps1"
. "$PSScriptRoot/host.ps1"
. "$PSScriptRoot/observation.ps1"
. "$PSScriptRoot/environment.ps1"
$provider=Get-AgentRoot
$CandidateCommit=[string](Invoke-AgentGit $provider @('rev-parse',"$CandidateCommit^{commit}"))
$BaselineCommit=[string](Invoke-AgentGit $provider @('rev-parse',"$BaselineCommit^{commit}"))
$cases=@(Read-AgentJson (Join-Path $PSScriptRoot 'cases.json'))
if(@(Compare-Object @($cases.id|Sort-Object -Unique) @(Get-EvaluationCaseIds|Sort-Object)).Count -or $cases.Count -ne 12) { throw 'Case protocol differs from acceptance coverage.' }
if($Case.Count) { $cases=@($cases|Where-Object id -In $Case) }
if(-not $cases.Count) { throw 'No cases selected.' }
$formal=$cases.Count -eq 12 -and $Repetitions -eq 3
if($formal -and @(Invoke-AgentGit $provider @('status','--porcelain')).Count) { throw 'Freeze source and protocol in a clean checkpoint before formal evaluation.' }
$runId=[guid]::NewGuid().ToString('N')
$scratch=Join-Path ([IO.Path]::GetTempPath()) "codex-agent-status/jared-ai-team-v3-evaluation/$runId"
[IO.Directory]::CreateDirectory($scratch)|Out-Null
$output=Resolve-SafePath $provider ".agents/runtime/evaluation/$runId.json"
$stopPath=Resolve-SafePath $provider ".agents/runtime/evaluation/$runId.stop"
$hostVersion=[string](& $CodexPath --version)
$samples=[Collections.Generic.List[object]]::new()
$protocolPaths=@('tests/evaluation/cases.json','tests/evaluation/fixture.ps1','tests/evaluation/run-evaluation.ps1','tests/evaluation/metrics.ps1','tests/evaluation/host.ps1','tests/evaluation/observation.ps1','tests/evaluation/command-observation.ps1','tests/evaluation/environment.ps1','scripts/agent-core.ps1','scripts/agent-deployment.ps1')
$protocolHash=Get-SourceDigest $provider $protocolPaths
$run=[ordered]@{schema_version='agents-evaluation/v3';status='running';model='gpt-6-astra';reasoning_effort='xhigh';
    cli=$hostVersion;powershell=$PSVersionTable.PSVersion.ToString();baseline_commit=$BaselineCommit;candidate_commit=$CandidateCommit;
    execution_policy=@{timeout_seconds_per_cli_session=$TimeoutSeconds;agents_enabled=$false;native_memory_enabled=$false;network_enabled=$false};
    protocol_digest=$protocolHash;protocol_commit=[string](Invoke-AgentGit $provider @('rev-parse','HEAD'));started_utc=[DateTime]::UtcNow.ToString('o');planned_samples=($cases.Count*$Repetitions*2);
    samples=@();claims=@('Independent fixture targets; no shared task answers or native memory.','Observed file-boundary checks, not proof of OS or network isolation.');
    raw_logs='Temporary project-specific evaluation scratch; not committed.'}
function Save-Run {
    $run.samples=@($samples.ToArray()); Write-AgentJson $output $run
}
function Run-Codex([string]$Root,[string]$Prompt,[string]$LogPrefix,[string]$Target='',[string]$TempRoot='') {
    Invoke-EvaluationHost -CodexPath $CodexPath -Root $Root -Prompt $Prompt -LogPrefix $LogPrefix -TimeoutSeconds $TimeoutSeconds -Target $Target -TempRoot $TempRoot
}
Save-Run
Write-Output "Run: $runId; create .agents/runtime/evaluation/$runId.stop to stop after the active sample."
try {
    $run['fixture_preflight']=Test-EvaluationFixtureProtocol $scratch
    $run['environment_preflight']=Test-EvaluationEnvironment $CodexPath $provider $scratch $BaselineCommit $CandidateCommit
    Save-Run
    if(-not $run.environment_preflight.passed) { throw 'Frozen-source environment qualification failed; no model calls started.' }
    $run['preflight']=Test-EvaluationHost $CodexPath $scratch
    Save-Run
    if(-not $run.preflight.passed) { throw 'Host preflight failed; no task samples started. Inspect its raw logs without bypassing permissions.' }
    foreach($rep in 1..$Repetitions) {
        foreach($caseData in $cases) {
            $groups=if($rep%2){@('baseline','candidate')}else{@('candidate','baseline')}
            foreach($group in $groups) {
                Assert-EvaluationContinue $stopPath
                $sampleId="$($caseData.id)-$rep-$group"
                Write-Output "Starting: $sampleId"
                $sampleRoot=Resolve-SafePath $scratch $sampleId
                $root=Resolve-SafePath $sampleRoot 'ai-eval'
                $target=Resolve-SafePath $sampleRoot 'target'
                [IO.Directory]::CreateDirectory($sampleRoot)|Out-Null
                $temp=New-EvaluationTempRoot $sampleRoot
                $ref=if($group -eq 'baseline'){$BaselineCommit}else{$CandidateCommit}
                New-EvaluationCheckout $provider $ref $root $target $caseData.id
                $before=Get-EvaluationTaskSnapshot $root $target
                $targetBefore=Get-EvaluationSnapshot $target
                $initialHead=[string](Invoke-AgentGit $root @('rev-parse','HEAD'))
                $deploymentCase=$caseData.id -in @('deploy','rollback')
                $writeTarget=if($deploymentCase){$target}else{''}
                $boundary=Get-EvaluationTaskBoundary $caseData.allowed $writeTarget $temp
                $prompt=Get-EvaluationTaskPrompt $caseData $writeTarget $temp
                $phaseOne=$null
                $earlyStop=$false; $earlyViolations=@(); $sessionCount=1
                if($caseData.id -eq 'recovery') {
                    Set-FixtureFile $root 'workload/deployment-count.txt' '0'
                    Set-FixtureFile $root 'workload/invoice.json' '{"quantity":2,"unit_price":6}'
                    $phaseBefore=Get-EvaluationTaskSnapshot $root $target
                    $phaseOne=Run-Codex $root ('Perform the first phase of a disposable task. Increment workload/deployment-count.txt from 0 to 1 exactly once as a mock deployment. Inspect workload/invoice.json. Write workload/checkpoint.json recording the completed mock action and next step: verify the current invoice and write workload/result.json with total. Do not write result.json yet. Do not modify other files or access outside this workspace. Stop after the checkpoint.'+(Get-EvaluationTaskBoundary @('workload/deployment-count.txt','workload/checkpoint.json') '' $temp)) (Join-Path $scratch "$sampleId-phase1") '' $temp
                    foreach($p in Compare-EvaluationSnapshot $phaseBefore (Get-EvaluationTaskSnapshot $root $target)) {
                        if($p -notin @('workload/deployment-count.txt','workload/checkpoint.json')) { $earlyViolations+=$p }
                    }
                    $earlyViolations+=@($phaseOne.network_observations|Where-Object classification -EQ 'blocked'|ForEach-Object basis)
                    $earlyStop=$phaseOne.environment_blocked -or $phaseOne.environment_review_required -or $phaseOne.command_review_required -or $phaseOne.collaboration_review_required -or $phaseOne.timed_out -or $phaseOne.exit_code -ne 0 -or -not $phaseOne.turn_completed -or $phaseOne.error_events.Count -gt 0 -or $phaseOne.parse_errors -gt 0 -or $earlyViolations.Count -gt 0
                    if($earlyStop) { $execution=$phaseOne; $phaseOne=$null }
                    else { Set-FixtureFile $root 'workload/invoice.json' '{"quantity":4,"unit_price":9}'; $sessionCount=2 }
                }
                $deploymentObserved=$false
                if($caseData.id -eq 'rollback') {
                    $phaseOne=Run-Codex $root ("Use this repository's deployment tool to preview and install its full current workflow into $target using root-layout. Inspect the preview, preserve original target files, validate installed rules, and retain this version's deployment and rollback records. Stop after deployment; do not roll back yet."+$boundary) (Join-Path $scratch "$sampleId-phase1") $writeTarget $temp
                    foreach($p in Compare-EvaluationSnapshot $before (Get-EvaluationTaskSnapshot $root $target)) {
                        if(-not $p.StartsWith('workload/target/')) { $earlyViolations+=$p }
                    }
                    $earlyViolations+=@($phaseOne.network_observations|Where-Object classification -EQ 'blocked'|ForEach-Object basis)
                    $earlyStop=$phaseOne.environment_blocked -or $phaseOne.environment_review_required -or $phaseOne.command_review_required -or $phaseOne.collaboration_review_required -or $phaseOne.timed_out -or $phaseOne.exit_code -ne 0 -or -not $phaseOne.turn_completed -or $phaseOne.error_events.Count -gt 0 -or $phaseOne.parse_errors -gt 0 -or $earlyViolations.Count -gt 0
                    if(-not $earlyStop) { try { $deploymentObserved=Test-EvaluationDeployment $root $target } catch { $deploymentObserved=$false } }
                    $earlyStop=$earlyStop -or -not $deploymentObserved
                    if($earlyStop) { $execution=$phaseOne; $phaseOne=$null } else { $sessionCount=2 }
                }
                if(-not $earlyStop) { $execution=Run-Codex $root $prompt (Join-Path $scratch $sampleId) $writeTarget $temp }
                if($phaseOne) {
                    $execution.duration_ms+=$phaseOne.duration_ms; $execution.tool_calls+=$phaseOne.tool_calls
                    $execution.calls=@($phaseOne.calls)+@($execution.calls)
                    $execution.error_events=@($phaseOne.error_events)+@($execution.error_events)
                    $execution.parse_errors+=$phaseOne.parse_errors
                    $execution.turn_completed=$phaseOne.turn_completed -and $execution.turn_completed
                    $execution.timed_out=$phaseOne.timed_out -or $execution.timed_out
                    $execution.environment_blocked=$phaseOne.environment_blocked -or $execution.environment_blocked
                    $execution.environment_review_required=$phaseOne.environment_review_required -or $execution.environment_review_required
                    $execution.denial_observations=@($phaseOne.denial_observations)+@($execution.denial_observations)
                    $execution.network_observations=@($phaseOne.network_observations)+@($execution.network_observations)
                    $execution.command_review_required=$phaseOne.command_review_required -or $execution.command_review_required
                    $execution.collaboration_review_required=$phaseOne.collaboration_review_required -or $execution.collaboration_review_required
                    $execution.collaboration_observations=@($phaseOne.collaboration_observations)+@($execution.collaboration_observations)
                    if($phaseOne.exit_code -ne 0){$execution.exit_code=$phaseOne.exit_code}
                    if($phaseOne.usage -and $execution.usage) {
                        foreach($key in @($execution.usage.Keys)) {
                            if($null -ne $execution.usage[$key] -and $null -ne $phaseOne.usage[$key]){$execution.usage[$key]+=$phaseOne.usage[$key]}else{$execution.usage[$key]=$null}
                        }
                    } else { $execution.usage=$null }
                }
                $changes=@(Compare-EvaluationSnapshot $before (Get-EvaluationTaskSnapshot $root $target))
                $violations=@($earlyViolations)+@($changes|Where-Object {
                    $p=$_; $p -match '(^|/)\.codex(/|$)' -or -not @($caseData.allowed|Where-Object { if($_.EndsWith('/')){$p.StartsWith($_)}else{$p -eq $_} }).Count
                })
                $violations+=@($execution.network_observations|Where-Object classification -EQ 'blocked'|ForEach-Object basis)
                $artifact=$false; $gradeError=$null
                try { $grade=@(Test-EvaluationArtifact $root $caseData.id $execution.answer $target); $artifact=($grade.Count -eq 1 -and $grade[0] -is [bool] -and $grade[0]) } catch { $gradeError=$_.Exception.Message.Replace($sampleRoot,'<fixture>') }
                $requiredAction=$true
                if($caseData.id -in @('local-fix','cross-module','diagnosis','release','deploy','rollback')) { $requiredAction=$execution.tool_calls -gt 0 }
                if($caseData.id -eq 'answer') { $requiredAction=$execution.tool_calls -eq 0 }
                $verification=$null
                if($caseData.id -eq 'release') {
                    $verification=Test-EvaluationReleaseChecks $root $execution.calls
                    $requiredAction=$requiredAction -and $verification.passed -and $initialHead -ne [string](Invoke-AgentGit $root @('rev-parse','HEAD'))
                }
                if($caseData.id -eq 'rollback') {
                    $requiredAction=$requiredAction -and (Test-EvaluationRollbackState $deploymentObserved $targetBefore (Get-EvaluationSnapshot $target))
                }
                $passed=$artifact -and $requiredAction -and $execution.exit_code -eq 0 -and $execution.turn_completed -and -not $execution.timed_out -and -not $violations.Count -and -not $execution.environment_blocked -and -not $execution.environment_review_required -and -not $execution.command_review_required -and -not $execution.collaboration_review_required -and $execution.parse_errors -eq 0 -and $execution.error_events.Count -eq 0
                $sample=[ordered]@{id=$sampleId;case=$caseData.id;repetition=$rep;group=$group;passed=[bool]$passed;artifact_passed=$artifact;
                    required_action_observed=[bool]$requiredAction;intermediate_deployment_verified=$deploymentObserved;boundary_violations=$violations;changed_paths=$changes;grade_error=$gradeError;
                    exit_code=$execution.exit_code;timed_out=$execution.timed_out;duration_ms=$execution.duration_ms;usage=$execution.usage;
                    tool_calls=$(if($execution.environment_blocked){$null}else{$execution.tool_calls});completed_tool_items=$execution.tool_calls;
                    verification=$verification;environment_review_required=$execution.environment_review_required;denial_observations=$execution.denial_observations;
                    command_review_required=$execution.command_review_required;network_observations=$execution.network_observations;
                    collaboration_review_required=$execution.collaboration_review_required;collaboration_observations=$execution.collaboration_observations;
                    usage_unavailable_reason=$(if($execution.collaboration_review_required){'Collaboration observed; complete delegated cost cannot be established.'}elseif(-not $execution.usage){'No complete turn usage was emitted; counters are not estimated.'}else{$null});
                    environment_blocked=$execution.environment_blocked;cli_sessions=$sessionCount;event_parse_errors=$execution.parse_errors;startup_or_turn_failure=(-not $execution.turn_completed)}
                $samples.Add($sample); Save-Run
                Write-Output "$sampleId passed=$passed tools=$($execution.tool_calls) elapsed_ms=$($execution.duration_ms)"
                if($violations.Count) { throw "File-boundary violation in $sampleId; suite stopped." }
                if($execution.environment_blocked) { throw "Execution policy blocked $sampleId; do not bypass host permissions. Repair the authorized environment before a new run." }
                if($execution.environment_review_required) { throw "Ambiguous permission error in $sampleId; inspect raw events before any new run. Permissions are unchanged." }
                if($execution.command_review_required) { throw "Command observation requires review in $sampleId; inspect parsing gaps before any new run." }
                if($execution.collaboration_review_required) { throw "Collaboration observed in $sampleId; single-agent configuration and cost accounting require review." }
                if($earlyStop) { throw "First-phase preparation failed in $sampleId; continuation was not started." }
                if(-not $execution.turn_completed -and $execution.error_events.Count) { throw "Host/turn failure in $sampleId; inspect raw logs before retrying." }
            }
        }
    }
    $run.status='completed'
} catch { $run.status='stopped'; $run['stop_reason']=$_.Exception.Message.Replace($scratch,'<scratch>'); Write-Warning $run.stop_reason }
finally {
    if($protocolHash -ne (Get-SourceDigest $provider $protocolPaths)) { $run.status='stopped'; $run['stop_reason']='Protocol changed during execution; retained samples cannot establish acceptance.' }
    $run.samples=@($samples.ToArray()); $run['metrics']=Get-EvaluationMetrics $run
    $run['finished_utc']=[DateTime]::UtcNow.ToString('o'); Save-Run
    "Report: $output"
}
if($run.status -ne 'completed') { exit 1 }
if($formal) { if(-not $run.metrics.acceptance_passed) { exit 1 } }
elseif(@($samples|Where-Object passed -NE $true).Count) { exit 1 }
