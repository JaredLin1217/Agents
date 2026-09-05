. "$PSScriptRoot/fixture.ps1"
. "$PSScriptRoot/host.ps1"
function New-EvaluationCheckout([string]$Provider,[string]$Ref,[string]$Root,[string]$Target,[string]$Case) {
    if(Test-Path -LiteralPath $Root) { throw 'Evaluation checkout must be fresh.' }
    [IO.Directory]::CreateDirectory($Root)|Out-Null
    Assert-EvaluationLaunchPath $Root
    $zip=Join-Path (Split-Path -Parent $Root) 'source.zip'
    $null=Invoke-AgentGit $Provider @('archive','--format=zip',"--output=$zip",$Ref)
    Expand-Archive -LiteralPath $zip -DestinationPath $Root
    Remove-EvaluationGradingFiles $Root
    $null=Invoke-AgentGit $Root @('init','-q')
    $null=Invoke-AgentGit $Root @('config','user.name','Evaluation')
    $null=Invoke-AgentGit $Root @('config','user.email','eval@example.invalid')
    # The frozen v2.9 validator reads v2.8 blobs. Import only that pre-evaluation history,
    # identically for both arms, without a remote or any v3 task answers.
    $history='8a2d46adf19d2ede1ca5cc5aff880ca5a4cc2a61'
    $null=Invoke-AgentGit $Root @('fetch','--no-tags','--no-write-fetch-head',$Provider,$history)
    New-EvaluationFixture $Root $Case $Target
    $null=Invoke-AgentGit $Root @('add','.')
    $null=Invoke-AgentGit $Root @('commit','-qm','independent evaluation fixture')
}
function Test-EvaluationDeploymentProtocol([string]$Root,[string]$Target,[string]$RecordRoot) {
    $native=Test-Path -LiteralPath (Join-Path $Root 'agents.json')
    if($native) {
        $preview=@(& pwsh -NoProfile -File (Join-Path $Root 'scripts/deploy-agents-workflow.ps1') -TargetPath $Target -LayoutProfile root-layout -DryRun)
        if($LASTEXITCODE -ne 0) { throw 'Reference deployment preview failed.' }
        $plan=ConvertFrom-Json -AsHashtable -InputObject ($preview -join "`n")
        $out=@(& pwsh -NoProfile -File (Join-Path $Root 'scripts/deploy-agents-workflow.ps1') -TargetPath $Target -LayoutProfile root-layout -ExpectedPlanDigest $plan.plan_digest 2>&1)
    } else {
        $out=@(& pwsh -NoProfile -File (Join-Path $Root 'scripts/deploy-agents-workflow.ps1') -TargetPath $Target -Mode full_workflow -LayoutProfile root-layout -Quiet 2>&1)
    }
    $exitCode=$LASTEXITCODE
    [IO.File]::WriteAllText((Join-Path $RecordRoot 'deployment-protocol.log'),($out -join "`n"))
    if($exitCode -ne 0) { throw 'Reference deployment failed.' }
    $valid=Test-EvaluationDeployment $Root $Target
    $rule=Resolve-SafePath $Target 'AGENTS.md'
    $original=[IO.File]::ReadAllBytes($rule)
    try {
        [IO.File]::WriteAllText($rule,'Invalid reference deployment.')
        $invalidRejected=-not(Test-EvaluationDeployment $Root $Target)
    } finally { [IO.File]::WriteAllBytes($rule,$original) }
    return @{passed=($valid -and $invalidRejected);valid_reference_passed=$valid;invalid_reference_rejected=$invalidRejected;model_started=$false}
}
function Test-EvaluationEnvironment([string]$CodexPath,[string]$Provider,[string]$Scratch,[string]$BaselineCommit,[string]$CandidateCommit) {
    $checks=[Collections.Generic.List[object]]::new()
    foreach($group in @('baseline','candidate')) {
        $base=Resolve-SafePath $Scratch "environment-$group"
        $root=Resolve-SafePath $base 'ai-eval'
        $target=Resolve-SafePath $base 'target'
        [IO.Directory]::CreateDirectory($base)|Out-Null
        $temp=New-EvaluationTempRoot $base
        $ref=if($group -eq 'baseline'){$BaselineCommit}else{$CandidateCommit}
        New-EvaluationCheckout $Provider $ref $root $target 'release'
        # Probe controls outside the source fixture so the validator sees only its prepared inputs.
        $probe=Resolve-SafePath $base 'boundary-probe'
        [IO.Directory]::CreateDirectory((Join-Path $probe '.agents/runtime'))|Out-Null
        $filesystem=Test-EvaluationFilesystem $CodexPath $probe $base $temp
        if(-not $filesystem.passed) {
            $checks.Add(@{group=$group;source_commit=$ref;passed=$false;filesystem=$filesystem;validator_started=$false})
            break
        }
        $before=Get-EvaluationTaskSnapshot $root $target
        $native=Test-Path -LiteralPath (Join-Path $root 'agents.json')
        $flags=if($native){@('-Scope','Provider','-Profile','Checkpoint','-Json')}else{@('-Full','-Score')}
        $arguments=@('sandbox','-P','agents-evaluation','--include-managed-config','-C',$root)+(Get-EvaluationPermissionArguments $temp)
        if($IsWindows) { $arguments+=@('-c','windows.sandbox="elevated"') }
        $arguments+=@('--',(Get-Command pwsh -ErrorAction Stop).Source,'-NoProfile','-NonInteractive','-File',(Join-Path $root 'scripts/validate.ps1'))+$flags
        $psi=New-EvaluationProcessInfo $CodexPath $root $temp
        foreach($arg in $arguments) { $psi.ArgumentList.Add($arg) }
        $process=[Diagnostics.Process]::new(); $process.StartInfo=$psi
        try {
            $timer=[Diagnostics.Stopwatch]::StartNew(); $null=$process.Start(); $process.StandardInput.Close()
            $stdout=$process.StandardOutput.ReadToEndAsync(); $stderr=$process.StandardError.ReadToEndAsync()
            $timedOut=-not $process.WaitForExit(300000)
            if($timedOut) { $process.Kill($true); $process.WaitForExit() }
            $timer.Stop(); $out=$stdout.GetAwaiter().GetResult(); $err=$stderr.GetAwaiter().GetResult(); $exitCode=$process.ExitCode
        } finally { $process.Dispose() }
        [IO.File]::WriteAllText((Join-Path $base 'validation.stdout.txt'),$out)
        [IO.File]::WriteAllText((Join-Path $base 'validation.stderr.txt'),$err)
        $changes=@(Compare-EvaluationSnapshot $before (Get-EvaluationTaskSnapshot $root $target))
        $success=$false
        if($exitCode -eq 0 -and -not $timedOut) {
            if($native) {
                try { $receipt=ConvertFrom-Json -AsHashtable -InputObject $out -ErrorAction Stop; $success=$receipt.passed -and $receipt.profile -eq 'Checkpoint' } catch {}
            } else { $success=$out -match 'Overall:\s+100\.0/100' -and $out -match '\[PASS\] Full release audit gates passed\.' -and $out -match '(?m)^Validation passed\.\s*$' }
        }
        $deployment=$null
        if($success -and $changes.Count -eq 0) { $deployment=Test-EvaluationDeploymentProtocol $root $target $base }
        $checks.Add(@{group=$group;source_commit=$ref;passed=([bool]$success -and $changes.Count -eq 0 -and $deployment.passed);
            deployment_protocol=$deployment;
            filesystem=$filesystem;validator_started=$true;exit_code=$exitCode;timed_out=$timedOut;duration_ms=$timer.ElapsedMilliseconds;
            command=('pwsh -NoProfile -NonInteractive -File scripts/validate.ps1 '+($flags -join ' '));changed_paths=$changes})
        if(-not $checks[-1].passed) { break }
    }
    return @{passed=($checks.Count -eq 2 -and @($checks|Where-Object passed -NE $true).Count -eq 0);checks=@($checks.ToArray());model_started=$false;
        claims=@('Full validation in independent frozen-source fixtures before model tasks.','Same invocation-only permissions and private temp topology for both arms.','Deployment grading accepts a complete reference and rejects damaged rules in both frozen versions before model calls.','Qualification overhead, not task usage or model correctness evidence.')}
}
