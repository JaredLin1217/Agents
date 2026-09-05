#requires -Version 7.0
param([Parameter(Mandatory)][string]$CodexPath,[Parameter(Mandatory)][string]$CandidateCommit,
      [string]$BaselineCommit='5e1643410233858ed70e4567beb01468fe0c2dc8',
      [ValidateRange(1,3)][int]$Repetitions=3,[ValidateRange(30,1800)][int]$TimeoutSeconds=600,
      [string[]]$Case=@())
. "$PSScriptRoot/fixture.ps1"
$provider=Get-AgentRoot
$cases=@(Read-AgentJson (Join-Path $PSScriptRoot 'cases.json'))
if($Case.Count) { $cases=@($cases|Where-Object id -In $Case) }
if(-not $cases.Count) { throw 'No cases selected.' }
$runId=[guid]::NewGuid().ToString('N')
$scratch=Join-Path ([IO.Path]::GetTempPath()) "codex-agent-status/jared-ai-team-v3-evaluation/$runId"
[IO.Directory]::CreateDirectory($scratch)|Out-Null
$output=Resolve-SafePath $provider ".agents/runtime/evaluation/$runId.json"
$hostVersion=[string](& $CodexPath --version)
$samples=[Collections.Generic.List[object]]::new()
$protocolHash=Get-SourceDigest $provider @('tests/evaluation/cases.json','tests/evaluation/fixture.ps1','tests/evaluation/run-evaluation.ps1')
$run=[ordered]@{schema_version='agents-evaluation/v3';status='running';model='gpt-6-astra';reasoning_effort='xhigh';
    cli=$hostVersion;powershell=$PSVersionTable.PSVersion.ToString();baseline_commit=$BaselineCommit;candidate_commit=$CandidateCommit;
    protocol_digest=$protocolHash;started_utc=[DateTime]::UtcNow.ToString('o');planned_samples=($cases.Count*$Repetitions*2);
    samples=@();claims=@('Independent fixture targets; no shared task answers or native memory.','Observed file-boundary checks, not proof of OS or network isolation.');
    raw_logs='Temporary project-specific evaluation scratch; not committed.'}
function Save-Run {
    $run.samples=@($samples.ToArray()); Write-AgentJson $output $run
}
function Run-Codex([string]$Root,[string]$Prompt,[string]$LogPrefix) {
    $psi=[Diagnostics.ProcessStartInfo]::new($CodexPath)
    $psi.WorkingDirectory=$Root; $psi.UseShellExecute=$false; $psi.CreateNoWindow=$true
    $psi.RedirectStandardOutput=$true; $psi.RedirectStandardError=$true; $psi.RedirectStandardInput=$true
    foreach($arg in @('exec','--strict-config','--ignore-user-config','--ephemeral','--json','--color','never',
        '-s','workspace-write','-C',$Root,'-m','gpt-6-astra','-c','model_reasoning_effort="xhigh"',
        '-c','memories.use_memories=false','-c','memories.generate_memories=false','-c','web_search="disabled"',
        '-c','features.multi_agent=false','-c','approval_policy="never"','-o',"$LogPrefix.answer.txt",'-')) { $psi.ArgumentList.Add($arg) }
    $process=[Diagnostics.Process]::new(); $process.StartInfo=$psi
    $timer=[Diagnostics.Stopwatch]::StartNew(); $null=$process.Start()
    $stdout=$process.StandardOutput.ReadToEndAsync(); $stderr=$process.StandardError.ReadToEndAsync()
    $process.StandardInput.Write($Prompt); $process.StandardInput.Close()
    $timedOut=-not $process.WaitForExit($TimeoutSeconds*1000)
    if($timedOut) { $process.Kill($true); $process.WaitForExit() }
    $timer.Stop(); $out=$stdout.GetAwaiter().GetResult(); $err=$stderr.GetAwaiter().GetResult()
    [IO.File]::WriteAllText("$LogPrefix.events.jsonl",$out)
    [IO.File]::WriteAllText("$LogPrefix.stderr.txt",$err)
    $events=@(); $parseErrors=0
    foreach($line in ($out -split "`n"|Where-Object {$_})) { try{$events+=ConvertFrom-Json -InputObject $line -AsHashtable -ErrorAction Stop}catch{$parseErrors++} }
    $usages=@($events|Where-Object { $_.type -eq 'turn.completed' -and $_.Contains('usage') }|ForEach-Object usage)
    $calls=@($events|Where-Object { $_.type -eq 'item.completed' -and $_.item.type -in @('command_execution','mcp_tool_call','web_search','tool_call','collab_tool_call','file_change') }|ForEach-Object item)
    $answer=if(Test-Path -LiteralPath "$LogPrefix.answer.txt"){Get-Content -Raw -LiteralPath "$LogPrefix.answer.txt"}else{''}
    $usage=$null
    if($usages.Count) {
        $usage=@{}; foreach($key in @('input_tokens','cached_input_tokens','cache_write_input_tokens','output_tokens','reasoning_output_tokens')) {
            $values=@($usages|Where-Object { $_.Contains($key) }|ForEach-Object {$_[$key]})
            $usage[$key]=if($values.Count -eq $usages.Count){($values|Measure-Object -Sum).Sum}else{$null}
        }
    }
    $result=@{exit_code=$process.ExitCode;timed_out=$timedOut;duration_ms=$timer.ElapsedMilliseconds;usage=$usage;
        tool_calls=@($calls|Group-Object id).Count;parse_errors=$parseErrors;answer=$answer;calls=$calls;
        turn_completed=($usages.Count -gt 0);error_events=@($events|Where-Object type -In @('error','turn.failed'))}
    $process.Dispose(); return $result
}
Save-Run
try {
    foreach($rep in 1..$Repetitions) {
        foreach($caseData in $cases) {
            $groups=if($rep%2){@('baseline','candidate')}else{@('candidate','baseline')}
            foreach($group in $groups) {
                $sampleId="$($caseData.id)-$rep-$group"
                $root=Join-Path $scratch $sampleId
                [IO.Directory]::CreateDirectory($root)|Out-Null
                $ref=if($group -eq 'baseline'){$BaselineCommit}else{$CandidateCommit}
                $zip=Join-Path $scratch "$sampleId.zip"
                $null=Invoke-AgentGit $provider @('archive','--format=zip',"--output=$zip",$ref)
                Expand-Archive -LiteralPath $zip -DestinationPath $root
                # The agent receives project sources, but not the independent grading protocol.
                $hidden=Resolve-SafePath $root 'tests/evaluation'
                if(Test-Path -LiteralPath $hidden) { Remove-Item -LiteralPath $hidden -Recurse -Force }
                $null=Invoke-AgentGit $root @('init','-q')
                $null=Invoke-AgentGit $root @('config','user.name','Evaluation')
                $null=Invoke-AgentGit $root @('config','user.email','eval@example.invalid')
                New-EvaluationFixture $root $caseData.id
                $null=Invoke-AgentGit $root @('add','.')
                $null=Invoke-AgentGit $root @('commit','-qm','independent evaluation fixture')
                $before=@{}; foreach($p in Get-AgentFiles $root) { $before[$p]=Get-AgentHash (Resolve-SafePath $root $p) }
                $initialHead=[string](Invoke-AgentGit $root @('rev-parse','HEAD'))
                $prompt=$caseData.prompt+"`nOnly this fixture workspace and its workload/target are authorized. No network, global settings, external projects, or shared memory. Do not inspect parent/sibling directories or grading material. Keep existing work. This is a disposable task, not permission to publish."
                $execution=Run-Codex $root $prompt (Join-Path $scratch $sampleId)
                $changes=@(); $after=@(Get-AgentFiles $root)
                foreach($p in @(@($before.Keys)+$after|Sort-Object -Unique)) {
                    $old=if($before.ContainsKey($p)){$before[$p]}else{'missing'}
                    if($old -ne (Get-AgentHash (Resolve-SafePath $root $p))) { $changes+=$p }
                }
                $violations=@($changes|Where-Object {
                    $p=$_; -not @($caseData.allowed|Where-Object { if($_.EndsWith('/')){$p.StartsWith($_)}else{$p -eq $_} }).Count
                })
                $artifact=$false; $gradeError=$null
                try { $artifact=[bool](Test-EvaluationArtifact $root $caseData.id $execution.answer) } catch { $gradeError=$_.Exception.Message.Replace($root,'<fixture>') }
                $requiredAction=$true
                if($caseData.id -in @('local-fix','cross-module','diagnosis','release','deploy','rollback')) { $requiredAction=$execution.tool_calls -gt 0 }
                if($caseData.id -eq 'answer') { $requiredAction=$execution.tool_calls -eq 0 }
                if($caseData.id -eq 'release') { $requiredAction=$requiredAction -and $initialHead -ne [string](Invoke-AgentGit $root @('rev-parse','HEAD')) }
                if($caseData.id -eq 'rollback') {
                    $requiredAction=$requiredAction -and @($execution.calls|Where-Object { ($_|ConvertTo-Json -Depth 15 -Compress) -match '(?i)rollback|restore-deployment' }).Count -gt 0
                }
                $passed=$artifact -and $requiredAction -and $execution.exit_code -eq 0 -and $execution.turn_completed -and -not $execution.timed_out -and -not $violations.Count
                $sample=[ordered]@{id=$sampleId;case=$caseData.id;repetition=$rep;group=$group;passed=[bool]$passed;artifact_passed=$artifact;
                    required_action_observed=[bool]$requiredAction;boundary_violations=$violations;changed_paths=$changes;grade_error=$gradeError;
                    exit_code=$execution.exit_code;timed_out=$execution.timed_out;duration_ms=$execution.duration_ms;usage=$execution.usage;
                    tool_calls=$execution.tool_calls;event_parse_errors=$execution.parse_errors;startup_or_turn_failure=(-not $execution.turn_completed)}
                $samples.Add($sample); Save-Run
                Write-Output "$sampleId passed=$passed tools=$($execution.tool_calls) elapsed_ms=$($execution.duration_ms)"
                if($violations.Count) { throw "File-boundary violation in $sampleId; suite stopped." }
                if(-not $execution.turn_completed -and $execution.error_events.Count) { throw "Host/turn failure in $sampleId; inspect raw logs before retrying." }
            }
        }
    }
    $run.status='completed'
} catch { $run.status='stopped'; $run['stop_reason']=$_.Exception.Message.Replace($scratch,'<scratch>'); Write-Warning $run.stop_reason }
finally {
    $run['finished_utc']=[DateTime]::UtcNow.ToString('o'); Save-Run
    "Report: $output"
}
if($run.status -ne 'completed') { exit 1 }
