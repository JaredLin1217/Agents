#requires -Version 7.0
param()
. "$PSScriptRoot/../scripts/agent-deployment.ps1"
$provider=Get-AgentRoot
$scratch=Resolve-SafePath $provider ('.agents/runtime/tests/'+[guid]::NewGuid().ToString('N'))
[IO.Directory]::CreateDirectory($scratch)|Out-Null
$script:assertions=0
function Assert($Condition,[string]$Message) { if(-not $Condition){throw $Message}; $script:assertions++ }
function Reject([scriptblock]$Action,[string]$Message) {
    $failed=$false; try { $null=& $Action } catch { $failed=$true }
    Assert $failed $Message
}
function Put([string]$Root,[string]$Path,[string]$Text) {
    $p=Resolve-SafePath $Root $Path
    [IO.Directory]::CreateDirectory((Split-Path -Parent $p))|Out-Null
    [IO.File]::WriteAllText($p,$Text,[Text.UTF8Encoding]::new($false))
}
function Init([string]$Root) {
    [IO.Directory]::CreateDirectory($Root)|Out-Null
    $null=Invoke-AgentGit $Root @('init','-q')
    $null=Invoke-AgentGit $Root @('config','user.name','Disposable Test')
    $null=Invoke-AgentGit $Root @('config','user.email','test@example.invalid')
    Put $Root '.gitignore' ".agents/runtime/`n"
    Put $Root 'README.md' 'User-owned product documentation'
    $null=Invoke-AgentGit $Root @('add','.')
    $null=Invoke-AgentGit $Root @('commit','-qm','fixture')
}
function Deploy([string]$Root,[string]$Layout='auto') {
    $plan=Invoke-Deployment $provider $Root $Layout '' -DryRun
    Assert ($plan.conflicts.Count -eq 0) 'Unexpected preview conflict'
    Invoke-Deployment $provider $Root $Layout $plan.plan_digest
}
function Recall([string]$Root) { (& "$provider/scripts/project-memory.ps1" -Root $Root)|ConvertFrom-Json -AsHashtable }
try {
    Reject { Resolve-SafePath $provider '../outside' } 'Traversal accepted'
    Reject { Resolve-SafePath $provider 'C:/outside' } 'Absolute path accepted'
    Reject { Resolve-SafePath $provider 'scripts/.. /outside' } 'Windows trailing-space traversal accepted'
    Reject { Resolve-SafePath $provider 'scripts/NUL.txt' } 'Windows device path accepted'
    Reject { Assert-OwnedPath 'docs/memory/entries/private.json' } 'Knowledge declared managed'
    Reject { Assert-OwnedPath '.codex/config.toml' } 'Local config declared managed'
    Reject { Assert-OwnedPath 'scripts/../docs/memory/private.json' } 'Aliased owned path accepted'
    Reject { Assert-OwnedPath 'scripts\\hidden.ps1' } 'Noncanonical owned path accepted'
    $deep=Join-Path $scratch 'long-path'
    Init $deep
    $deepFile=('nested-'*20)+'/deep.txt'
    Put $deep $deepFile 'Long path fixture'
    $null=Invoke-AgentGit $deep @('add',$deepFile)
    $null=Invoke-AgentGit $deep @('commit','-qm','long path change')
    Assert ((Invoke-AgentGit $deep @('show',"HEAD:$deepFile")) -eq 'Long path fixture') 'Git failed on a deep Windows file path'
    foreach($layout in @('root-layout','dot-agents-layout')) {
        $root=Join-Path $scratch ($layout+' '+[char]0x6E2C+[char]0x8A66)
        Init $root
        Put $root 'business.ps1' 'function Product { 42 }'
        $before=Get-SourceDigest $root (Get-AgentFiles $root)
        $plan=Invoke-Deployment $provider $root $layout '' -DryRun
        Assert ($before -eq (Get-SourceDigest $root (Get-AgentFiles $root))) 'Dry-run wrote files'
        Assert (-not(Test-Path -LiteralPath (Join-Path $root '.agents/runtime'))) 'Dry-run wrote state'
        Reject { Invoke-Deployment $provider $root $layout 'bad' } 'Unapproved deployment accepted'
        $run=Invoke-Deployment $provider $root $layout $plan.plan_digest
        Assert ($run.status -eq 'committed') 'Deployment failed'
        $manifest=Read-AgentJson (Join-Path $root '.agents/managed.json') (Join-Path $provider 'schemas/managed.schema.json')
        foreach($entry in $manifest.files) { Assert ((Get-AgentHash (Resolve-SafePath $root $entry.path)) -eq $entry.sha256) "Bad deployed hash $($entry.path)" }
        Assert ((Get-Content -Raw -LiteralPath (Join-Path $root 'README.md')) -eq 'User-owned product documentation') 'Product docs changed'
        Assert ((Deploy $root).status -eq 'unchanged') 'Repeated deployment not idempotent'
        $validator=Get-AgentAsset $root 'scripts/validate.ps1'
        $out=@(& pwsh -NoProfile -File $validator -Scope Consumer -Profile Checkpoint -Json 2>&1)
        Assert ($LASTEXITCODE -eq 0) "Consumer failed: $($out -join ' ')"
        $report=($out -join "`n")|ConvertFrom-Json -AsHashtable
        Assert ($report.checks.id -notcontains 'regression' -and $report.checks.id -notcontains 'size') 'Consumer ran provider checks'
        Assert (@($report.checks|Group-Object id|Where-Object Count -GT 1).Count -eq 0) 'Duplicate check'
        Put $root 'AGENTS.md' 'User change'
        $conflict=Invoke-Deployment $provider $root 'auto' '' -DryRun
        Assert ($conflict.conflicts.Count -gt 0) 'Managed edit undetected'
        Reject { Invoke-Deployment $provider $root 'auto' $conflict.plan_digest } 'Managed edit overwritten'
        Reject { Restore-Deployment $root $run.transaction_id } 'Rollback overwrote user edit'
        [IO.File]::Copy((Join-Path $provider 'AGENTS.md'),(Join-Path $root 'AGENTS.md'),$true)
        $journalPath=Join-Path $root ".agents/runtime/deployments/$($run.transaction_id).json"
        $journal=Read-AgentJson $journalPath
        $journal.status='applying'; Write-AgentJson $journalPath $journal
        $interruptedPlan=Get-DeploymentPlan $provider $root 'auto'
        Assert (@($interruptedPlan.operations|Where-Object action -NE 'unchanged').Count -eq 0) 'Interrupted fixture must already have final content'
        Reject { Invoke-Deployment $provider $root 'auto' $interruptedPlan.plan_digest } 'No-op bypassed an interrupted transaction'
        Put $root '.agents/runtime/deployment.lock' ''
        Reject { Invoke-Deployment $provider $root 'auto' $interruptedPlan.plan_digest } 'No-op bypassed the deployment lock'
        $restored=Restore-Deployment $root $run.transaction_id
        Assert ($restored.status -eq 'rolled_back') 'Interrupted rollback failed'
        Assert (-not(Test-Path -LiteralPath (Join-Path $root 'AGENTS.md'))) 'Rollback retained new rules'
        Assert (Test-Path -LiteralPath (Join-Path $root 'business.ps1')) 'Rollback deleted business code'
        $null=Deploy $root $layout
        # A verified retired file is deleted; a modified retired file is preserved.
        Put $root 'scripts/retired.ps1' '# prior managed file'
        $m=Read-AgentJson (Join-Path $root '.agents/managed.json')
        $m.files+=@{source='scripts/retired.ps1';path='scripts/retired.ps1';sha256=(Get-AgentHash (Join-Path $root 'scripts/retired.ps1'))}
        Write-AgentJson (Join-Path $root '.agents/managed.json') $m
        Put $root 'scripts/retired.ps1' '# user edit'
        Assert ((Get-DeploymentPlan $provider $root 'auto').conflicts.Count -gt 0) 'Modified retirement accepted'
        Put $root 'scripts/retired.ps1' '# prior managed file'
        $upgrade=Deploy $root
        Assert (-not(Test-Path -LiteralPath (Join-Path $root 'scripts/retired.ps1'))) 'Retired file retained'
        $upgradeJournal=Join-Path $root ".agents/runtime/deployments/$($upgrade.transaction_id).json"
        $backupJournal=Read-AgentJson $upgradeJournal
        $damaged=Read-AgentJson $upgradeJournal
        $damaged.entries[0].backup='YmFk'; Write-AgentJson $upgradeJournal $damaged
        Reject { Restore-Deployment $root $upgrade.transaction_id } 'Damaged rollback backup accepted'
        Write-AgentJson $upgradeJournal $backupJournal
        $null=Restore-Deployment $root $upgrade.transaction_id
        Assert (Test-Path -LiteralPath (Join-Path $root 'scripts/retired.ps1')) 'Retired file not restored'
    }
    $root=Join-Path $scratch 'memory recovery'
    Init $root; $null=Deploy $root 'root-layout'
    Put $root 'contract.txt' 'Durable fact'
    $entry=@{schema_version='agents-knowledge/v3';id='fact-one';type='fact';conclusion='Keep this verified fact';scope='example';
        sources=@(@{path='contract.txt';sha256=(Get-AgentHash (Join-Path $root 'contract.txt'));commit=([string](Invoke-AgentGit $root @('rev-parse','HEAD')))});
        verified_utc=[DateTime]::UtcNow.ToString('o');verification='Fixture assertion';status='active';supersedes=@();sensitive=$false}
    Write-AgentJson (Join-Path $root '.agents/runtime/input.json') $entry
    $memory=Get-AgentAsset $root 'scripts/project-memory.ps1'
    $null=& $memory -Action Promote -Root $root -InputPath '.agents/runtime/input.json'
    Assert ((Recall $root).entries.Count -eq 1) 'Fresh memory missing'
    Reject { & $memory -Action Promote -Root $root -InputPath '.agents/runtime/input.json' } 'Immutable entry overwritten'
    Put $root '.agents/runtime/memory-index.json' 'broken index'
    Assert ((Recall $root).entries.Count -eq 1) 'Corrupt index influenced recall'
    Put $root 'contract.txt' 'Changed fact'
    Assert ((Recall $root).entries.Count -eq 0) 'Stale memory recalled'
    $entry.id='fact-two'; $entry.sources[0].sha256=Get-AgentHash (Join-Path $root 'contract.txt'); $entry.supersedes=@('fact-one')
    Write-AgentJson (Join-Path $root '.agents/runtime/input.json') $entry
    $null=& $memory -Action Promote -Root $root -InputPath '.agents/runtime/input.json'
    Assert ((Recall $root).entries.Count -eq 1 -and (Recall $root).gaps.Count -eq 0) 'Supersession did not resolve staleness'
    $entry.id='conflict'; $entry.status='conflicted'; $entry.supersedes=@()
    Write-AgentJson (Join-Path $root 'docs/memory/entries/conflict.json') $entry
    Assert ((Recall $root).entries.Count -eq 0) 'Conflicted knowledge recalled'
    $entry.id='resolved'; $entry.status='active'; $entry.supersedes=@('fact-two','conflict')
    Write-AgentJson (Join-Path $root '.agents/runtime/input.json') $entry
    $null=& $memory -Action Promote -Root $root -InputPath '.agents/runtime/input.json'
    Assert ((Recall $root).entries.Count -eq 1 -and (Recall $root).gaps.Count -eq 0) 'Reviewed replacement could not resolve a conflict'
    $entry.id='cycle-one'; $entry.supersedes=@('cycle-two')
    Write-AgentJson (Join-Path $root 'docs/memory/entries/cycle-one.json') $entry
    $entry.id='cycle-two'; $entry.supersedes=@('cycle-one')
    Write-AgentJson (Join-Path $root 'docs/memory/entries/cycle-two.json') $entry
    Assert ((Recall $root).entries.Count -eq 0 -and (Recall $root).gaps.Count -gt 0) 'Cyclic knowledge failed silently'
    Remove-Item -LiteralPath (Join-Path $root 'docs/memory/entries/cycle-one.json'),(Join-Path $root 'docs/memory/entries/cycle-two.json')
    $retirement=Join-Path $scratch 'memory retirement'; Init $retirement; $null=Deploy $retirement 'root-layout'
    foreach($id in @('old','new')) {
        Put $retirement "$id.txt" "$id policy"
        $retiredEntry=@{schema_version='agents-knowledge/v3';id=$id;type='fact';conclusion="$id policy";scope='retention';
            sources=@(@{path="$id.txt";sha256=(Get-AgentHash (Join-Path $retirement "$id.txt"));commit=([string](Invoke-AgentGit $retirement @('rev-parse','HEAD')))});
            verified_utc=[DateTime]::UtcNow.ToString('o');verification='Retirement regression';status='active';
            supersedes=@($(if($id -eq 'new'){'old'}));sensitive=$false}
        Write-AgentJson (Join-Path $retirement "docs/memory/entries/$id.json") $retiredEntry
    }
    Assert ((Recall $retirement).entries.id -eq 'new') 'Replacement was not selected'
    Put $retirement 'new.txt' 'Unverified update'
    $staleReplacement=Recall $retirement
    Assert ($staleReplacement.entries.Count -eq 0 -and $staleReplacement.gaps -contains 'Source changed: new') 'Stale replacement resurrected retired knowledge'
    Remove-Item -LiteralPath (Join-Path $retirement 'new.txt')
    Assert ((Recall $retirement).entries.Count -eq 0) 'Missing replacement source resurrected retired knowledge'
    Put $retirement 'new.txt' 'new policy'
    Assert ((Recall $retirement).entries.id -eq 'new') 'Reverified replacement failed to recover'
    Put $retirement 'docs/memory/entries/new.json' '{broken'
    $invalidReplacement=Recall $retirement
    Assert ($invalidReplacement.entries.Count -eq 0 -and $invalidReplacement.gaps -contains 'Invalid knowledge: new.json') 'Unreadable replacement resurrected retired knowledge'
    Write-AgentJson (Join-Path $root '.agents/runtime/immutable.json') @{value=1}
    Reject { Write-AgentJson (Join-Path $root '.agents/runtime/immutable.json') @{value=2} -NoClobber } 'Exclusive JSON creation overwrote a file'
    $state=@{id='resume-test';objective='Finish task';latest_adjustment='Preserve user work';boundaries=@('contract.txt');completed=@('inspect');open_issues=@();next_steps=@('verify')}
    Write-AgentJson (Join-Path $root '.agents/runtime/task.json') $state
    $task=Get-AgentAsset $root 'scripts/task-state.ps1'
    $saved=(& $task -Action Save -Root $root -InputPath '.agents/runtime/task.json')|ConvertFrom-Json -AsHashtable
    Assert (-not $saved.requires_reinspection) 'Fresh checkpoint reported stale'
    Put $root 'contract.txt' 'Concurrent change'
    $resume=(& $task -Action Resume -Root $root -Id resume-test)|ConvertFrom-Json -AsHashtable
    Assert ($resume.requires_reinspection -and $resume.changed_files -contains 'contract.txt') 'Resume trusted stale state'
    Put $root 'bad.ps1' 'function {'
    Put $root 'bad.json' '{'
    $context=Get-AgentAsset $root 'scripts/resolve-agent-context.ps1'
    $result=(& $context -Root $root -Path @('bad.ps1','bad.json','contract.txt') -Format Json)|ConvertFrom-Json -AsHashtable
    Assert ($result.gaps.Count -eq 3) 'Parse/unsupported gaps hidden'
    Assert (-not $result.complete) 'Context claimed complete impact'
    $small=& $context -Root $root -Path @('bad.ps1','bad.json','contract.txt') -Format Json -BudgetBytes 512
    Assert ([Text.Encoding]::UTF8.GetByteCount($small) -le 512) 'Context budget exceeded'
    $other=Join-Path $scratch 'unowned'; Init $other; Put $other 'AGENTS.md' 'Private rules'
    Assert ((Get-DeploymentPlan $provider $other 'root-layout').conflicts.Count -gt 0) 'Unowned rules accepted'
    Put $other 'agents.json' '{"runtime_directory":".git"}'
    Reject { Get-ProjectSettings $other } 'Runtime redirected into Git metadata'
    Put $other 'agents.json' '{"knowledge_directory":"business"}'
    Reject { Get-ProjectSettings $other } 'Knowledge redirected into business files'
    $linked=Join-Path $scratch 'linked'
    $null=New-Item -ItemType Junction -Path $linked -Target $root
    Reject { Resolve-SafePath $scratch 'linked/contract.txt' } 'Junction traversal accepted'
    Remove-Item -LiteralPath $linked
    . "$PSScriptRoot/evaluation/metrics.ps1"
    . "$PSScriptRoot/evaluation/host.ps1"
    . "$PSScriptRoot/evaluation/observation.ps1"
    $taskBoundary=Get-EvaluationTaskBoundary @('workload/pricing.ps1','workload/order.ps1')
    Assert ($taskBoundary.Contains('workload/pricing.ps1; workload/order.ps1')) 'Task write scope hidden from the evaluated agent'
    Assert ($taskBoundary.Contains('including tests not listed here') -and $taskBoundary.Contains('.agents/runtime/')) 'Task read-only and temporary-write boundaries missing'
    Assert ((Get-EvaluationTaskBoundary @()).Contains('Writable task files: none.')) 'Read-only task received write authority'
    Reject { Get-EvaluationTaskBoundary @('workload/target/') } 'Deployment boundary accepted without target'
    Assert ((Get-EvaluationTaskBoundary @('workload/target/') 'exact disposable target').Contains('managed deployment file set under exact disposable target')) 'Logical target path leaked into the physical authorization'
    $promptCase=@{prompt='Fix the application.';acceptance=@('Negative quantities must throw.');allowed=@('workload/pricing.ps1')}
    $taskPrompt=Get-EvaluationTaskPrompt $promptCase
    Assert ($taskPrompt.Contains('Acceptance criteria:') -and $taskPrompt.Contains('Negative quantities must throw.') -and $taskPrompt.Contains('workload/pricing.ps1')) 'Visible criteria or write boundary missing'
    Reject { Get-EvaluationTaskPrompt @{prompt='Fix it';allowed=@()} } 'Task accepted without public criteria'
    Reject { Get-EvaluationTaskPrompt @{prompt='Fix it';acceptance=@(' ');allowed=@()} } 'Empty public criteria accepted'
    $stopPath=Join-Path $scratch 'run.stop'
    Assert-EvaluationContinue $stopPath
    Put $scratch 'run.stop' 'Stop after the active sample.'
    Reject { Assert-EvaluationContinue $stopPath } 'Operator stop ignored'
    # Model fixtures omit independent graders; their host-only tests must not leak answers.
    if(Test-Path -LiteralPath "$PSScriptRoot/evaluation/fixture.ps1") {
        . "$PSScriptRoot/evaluation/fixture.ps1"
        $fixturePreflight=Test-EvaluationFixtureProtocol (Join-Path $scratch 'protocol')
        Assert ($fixturePreflight.passed -and -not $fixturePreflight.model_started -and $fixturePreflight.checks.Count -eq 12) 'Incomplete offline protocol preflight'
        foreach($check in $fixturePreflight.checks) { Assert ($check.valid_reference_passed -and $check.invalid_reference_rejected) "Protocol references failed: $($check.case)" }
    }
    $observed=Join-Path $scratch 'observed target'; Init $observed
    Put $observed 'workload/target/README.md' 'Nested product'
    Put $observed '.gitignore' ".agents/runtime/`nworkload/target/`n"
    $snapshot=Get-EvaluationSnapshot $observed
    Put $observed 'workload/target/README.md' 'Unauthorized nested edit'
    Put $observed 'workload/target/ignored.txt' 'Ignored but observable'
    Put $observed '.agents/runtime/log.txt' 'Allowed scratch'
    $changes=@(Compare-EvaluationSnapshot $snapshot (Get-EvaluationSnapshot $observed))
    Assert ($changes -contains 'workload/target/README.md' -and $changes -contains 'workload/target/ignored.txt') 'Nested ignored changes escaped observation'
    Assert ($changes -notcontains '.agents/runtime/log.txt') 'Runtime logs counted as source edits'
    Put $observed 'tests/evaluation/cases.json' '[]'
    Put $observed 'tests/evaluation/fixture.ps1' '# Hidden grading'
    Put $observed 'tests/evaluation/run-evaluation.ps1' '# Hidden protocol'
    Put $observed 'tests/evaluation/metrics.ps1' '# Regression dependency'
    Put $observed 'tests/evaluation/host.ps1' '# Regression dependency'
    Put $observed 'tests/evaluation/environment.ps1' '# Host-only qualification'
    Put $observed 'docs/evidence/evaluation/prior.json' '{"passed":false}'
    Put $observed 'docs/evidence/v3-evaluation-status.json' '{"release_ready":false}'
    Put $observed 'docs/evidence/baseline.json' '{}'
    Remove-EvaluationGradingFiles $observed
    Assert (-not(Test-Path -LiteralPath (Join-Path $observed 'tests/evaluation/cases.json')) -and -not(Test-Path -LiteralPath (Join-Path $observed 'tests/evaluation/fixture.ps1'))) 'Fixture retained hidden prompts or graders'
    Assert ((Test-Path -LiteralPath (Join-Path $observed 'tests/evaluation/metrics.ps1')) -and (Test-Path -LiteralPath (Join-Path $observed 'tests/evaluation/host.ps1'))) 'Fixture removed regression dependencies'
    foreach($path in @('tests/evaluation/environment.ps1','docs/evidence/evaluation/prior.json','docs/evidence/v3-evaluation-status.json')) {
        Assert (-not(Test-Path -LiteralPath (Join-Path $observed $path))) 'Fixture retained previous outcomes or host-only qualification'
    }
    Assert (Test-Path -LiteralPath (Join-Path $observed 'docs/evidence/baseline.json')) 'Fixture lost required frozen baseline metadata'
    $separate=Join-Path $scratch 'separate target'; Init $separate
    Put $separate 'README.md' 'Target-owned product documentation.'
    $original=Get-EvaluationSnapshot $separate
    Assert (-not(Test-EvaluationDeployment $provider $separate)) 'Empty target accepted as installed'
    $deployed=Deploy $separate 'root-layout'
    Assert (Test-EvaluationDeployment $provider $separate) 'Complete installed assets rejected'
    Reject { Get-EvaluationTaskSnapshot $observed $separate } 'Overlapping logical target paths accepted'
    $observedBoth=Get-EvaluationTaskSnapshot $other $separate
    Assert ($observedBoth.ContainsKey('workload/target/AGENTS.md')) 'Separate target absent from observed boundary'
    Put $separate 'scripts/validate.ps1' '# Incorrect installed bytes'
    Assert (-not(Test-EvaluationDeployment $provider $separate)) 'Damaged installed script accepted'
    [IO.File]::Copy((Join-Path $provider 'scripts/validate.ps1'),(Join-Path $separate 'scripts/validate.ps1'),$true)
    Assert (-not(Test-EvaluationRollbackState $true $original (Get-EvaluationSnapshot $separate))) 'Retained deployment accepted as rollback'
    $null=Restore-Deployment $separate $deployed.transaction_id
    Assert (Test-EvaluationRollbackState $true $original (Get-EvaluationSnapshot $separate)) 'Verified rollback rejected'
    Assert (-not(Test-EvaluationRollbackState $false $original (Get-EvaluationSnapshot $separate))) 'No-op accepted as rollback'
    $hostArgs=@(Get-EvaluationHostArguments $scratch (Join-Path $scratch 'sample'))
    Assert ($hostArgs -contains 'default_permissions="agents-evaluation"' -and $hostArgs -contains 'approval_policy="never"') 'Evaluation permissions changed'
    Assert ($hostArgs -notcontains '-s' -and $hostArgs -notcontains '--sandbox') 'Legacy sandbox overrides the permission profile'
    $permissionConfig=@($hostArgs|Where-Object { $_.StartsWith('permissions=') })
    Assert ($permissionConfig.Count -eq 1 -and $permissionConfig[0].Contains('":workspace_roots"={"."="write"')) 'Evaluation profile is not a scoped TOML value'
    foreach($name in @('.agents','.git')) {
        Assert ($permissionConfig[0].Contains(('"'+$name+'"="write"'))) 'Authorized fixture metadata is not writable'
    }
    Assert ($permissionConfig[0].Contains('".codex"="read"')) 'Local configuration protection removed'
    Assert ($permissionConfig[0].Contains('network={enabled=false}')) 'Command network enabled'
    Reject { Get-EvaluationPermissionArguments $provider } 'Non-disposable extra temp accepted'
    $tempBoundary=Get-EvaluationTaskBoundary @() '' 'exact private temp'
    Assert ($tempBoundary.Contains('exact private temp') -and $tempBoundary.Contains('without a -TempRoot override')) 'Private temp contract absent'
    $launchRejected=$false; try { Assert-EvaluationLaunchPath ([IO.Path]::GetPathRoot($provider)) } catch { $launchRejected=$true }
    Assert $launchRejected 'Model launch accepted a non-disposable repository'
    Assert ($hostArgs -notcontains '--ignore-rules' -and $hostArgs -notcontains '--dangerously-bypass-approvals-and-sandbox') 'Evaluation bypasses host controls'
    if($IsWindows) { Assert ($hostArgs -contains 'windows.sandbox="elevated"') 'Windows backend dropped with user config' }
    $targetArgs=@(Get-EvaluationHostArguments $scratch (Join-Path $scratch 'sample') $separate)
    Assert ($targetArgs -contains '--add-dir' -and $targetArgs[$targetArgs.IndexOf('--add-dir')+1] -eq $separate -and $hostArgs -notcontains '--add-dir') 'Target access not scoped to deployment tasks'
    $events=@(
        '{"type":"item.started","item":{"id":"one","type":"command_execution"}}',
        '{"type":"item.completed","item":{"id":"one","type":"command_execution","status":"completed","exit_code":0,"aggregated_output":"OK"}}',
        '{"type":"turn.completed","usage":{"input_tokens":100,"cached_input_tokens":60,"output_tokens":10,"reasoning_output_tokens":4}}') -join "`n"
    $parsed=Convert-EvaluationEvents $events ''
    Assert ($parsed.tool_calls -eq 1 -and $parsed.usage.input_tokens -eq 100 -and $parsed.usage.output_tokens -eq 10) 'Host usage double counted'
    Assert ($null -eq $parsed.usage.cache_write_input_tokens) 'Missing host usage fabricated'
    Assert ((Convert-EvaluationEvents $events 'blocked by policy').environment_blocked) 'Stderr policy denial missed'
    $deniedEvents=$events.Replace('OK','Access is denied').Replace('"exit_code":0','"exit_code":1').Replace('"status":"completed"','"status":"failed"')
    Assert ((Convert-EvaluationEvents $deniedEvents '').environment_blocked) 'Failed command denial missed'
    $zeroExit=Convert-EvaluationEvents ($events.Replace('OK','Set-Content: Access to the path x is denied.')) ''
    Assert ($zeroExit.environment_review_required -and -not $zeroExit.environment_blocked) 'Zero-exit error silently accepted or overclaimed'
    $literal=Convert-EvaluationEvents ($events.Replace('OK',"Assert (Test-Error 'Access is denied') 'Expected denial'")) ''
    Assert (-not $literal.environment_blocked -and -not $literal.environment_review_required -and $literal.denial_observations[0].classification -eq 'mention') 'Source literal misclassified as execution failure'
    $sourceText=Get-Content -Raw -LiteralPath $PSCommandPath
    $sourceEvent=@{type='item.completed';item=@{id='source';type='command_execution';status='completed';exit_code=0;aggregated_output=$sourceText}}|ConvertTo-Json -Depth 6 -Compress
    $sourceRead=Convert-EvaluationEvents $sourceEvent ''
    Assert (-not $sourceRead.environment_blocked -and -not $sourceRead.environment_review_required) 'Reading regression source triggers a policy failure'
    Assert ((Convert-EvaluationEvents '{"type":"turn.failed","error":{"message":"Command blocked by policy"}}' '').environment_blocked) 'Structured turn denial missed'
    Assert ((Convert-EvaluationEvents '{"type":"item.completed","item":{"id":"denied","type":"tool_call","error":{"message":"permission denied"}}}' '').environment_blocked) 'Structured tool denial missed'
    Assert ((Convert-EvaluationEvents ($events+"`nbroken") '').parse_errors -eq 1) 'Malformed host events ignored'
    $rendered=@'
"C:\\Program Files\\PowerShell\\7\\pwsh.exe" -Command 'rg -n '"'"'Invoke-WebRequest|git fetch|https?://'"'"' scripts'
'@
    $argv=ConvertFrom-EvaluationCommandLine $rendered
    Assert ($argv.Count -eq 3 -and $argv[2] -eq "rg -n 'Invoke-WebRequest|git fetch|https?://' scripts") 'Rendered argv quoting decoded incorrectly'
    $commandCall=@{id='command';type='command_execution';exit_code=0;command=$rendered}
    Assert (@(Get-EvaluationNetworkObservations @($commandCall)).Count -eq 0) 'Search argument misclassified as a network invocation'
    foreach($command in @('Invoke-WebRequest https://example.invalid','git -c core.fsmonitor=false fetch origin','git -C . ls-remote origin')) {
        $commandCall.command=$command
        Assert (@(Get-EvaluationNetworkObservations @($commandCall)|Where-Object classification -EQ 'blocked').Count -eq 1) 'Direct network invocation missed'
    }
    $commandCall.command="git commit -m 'Do not git fetch or Invoke-WebRequest'"
    Assert (@(Get-EvaluationNetworkObservations @($commandCall)).Count -eq 0) 'Commit message treated as execution'
    foreach($command in @('pwsh -EncodedCommand abc','pwsh -Command "unfinished','git $operation origin','iex $text')) {
        $commandCall.command=$command
        Assert (@(Get-EvaluationNetworkObservations @($commandCall)|Where-Object classification -EQ 'review').Count -eq 1) 'Unparseable or dynamic operation silently accepted'
    }
    $releaseRoot=Join-Path $scratch 'release observation'; Init $releaseRoot
    Put $releaseRoot 'agents.json' '{}'
    $ids=@('syntax','json-schema','ownership','knowledge','sources','size','regression','evidence','package','diff')
    $receipt=@{scope='Provider';profile='Checkpoint';passed=$true;input_digest=(Get-SourceDigest $releaseRoot @(Get-AgentFiles $releaseRoot));
        checks=@($ids|ForEach-Object {@{id=$_;result='passed';exit_code=0}})}
    $releaseCalls=@(
        @{id='check';type='command_execution';exit_code=0;command='pwsh -NoProfile -File workload/check.ps1';aggregated_output='PASS'},
        @{id='checkpoint';type='command_execution';exit_code=0;command='pwsh -NoProfile -File scripts/validate.ps1 -Scope Provider -Profile Checkpoint -Json';aggregated_output=($receipt|ConvertTo-Json -Depth 6)},
        @{id='commit';type='command_execution';exit_code=0;command='git -c core.fsmonitor=false commit -m release';aggregated_output='[main abc1234] release'})
    Assert ((Test-EvaluationReleaseChecks $releaseRoot $releaseCalls).passed) 'Observed complete release rejected'
    Assert ((Test-EvaluationReleaseChecks $releaseRoot @($releaseCalls+$releaseCalls[0..1])).passed) 'Post-commit recheck erased valid pre-commit evidence'
    Assert (-not(Test-EvaluationReleaseChecks $releaseRoot @($releaseCalls[0],$releaseCalls[2])).passed) 'Missing checkpoint accepted'
    Assert (-not(Test-EvaluationReleaseChecks $releaseRoot @($releaseCalls[2],$releaseCalls[0],$releaseCalls[1])).passed) 'Post-commit validation accepted'
    $releaseCalls[1].command='pwsh -NoProfile -File scripts/validate.ps1 -Scope Provider -Profile Changed -Json'
    Assert (-not(Test-EvaluationReleaseChecks $releaseRoot $releaseCalls).passed) 'Changed substituted for Checkpoint'
    $releaseCalls[1].command='Get-Content -LiteralPath scripts/validate.ps1 -Scope Provider -Profile Checkpoint -Json'
    Assert (-not(Test-EvaluationReleaseChecks $releaseRoot $releaseCalls).passed) 'Reading a validator counted as running it'
    $releaseCalls[1].command='pwsh -NoProfile -File scripts/validate.ps1 -Scope Provider -Profile Checkpoint -Json'
    Put $releaseRoot 'changed.txt' 'Invalidate receipt'
    Assert (-not(Test-EvaluationReleaseChecks $releaseRoot $releaseCalls).passed) 'Stale validation receipt accepted'
    $baselineRoot=Join-Path $scratch 'baseline release observation'; Init $baselineRoot
    $releaseCalls[1].command='pwsh -NoProfile -File scripts/validate.ps1 -Full -Score'
    $releaseCalls[1].aggregated_output="[PASS] Full release audit gates passed.`nValidation passed.`n"
    Assert ((Test-EvaluationReleaseChecks $baselineRoot $releaseCalls).passed) 'Frozen baseline full validation rejected'
    $releaseCalls[1].aggregated_output='Validation passed.'
    Assert (-not(Test-EvaluationReleaseChecks $baselineRoot $releaseCalls).passed) 'Baseline partial validation accepted'
    $probe=@{status='completed';planned_samples=2;samples=@(
        @{case='answer';repetition=1;group='baseline';passed=$true;usage=@{input_tokens=100};tool_calls=0;event_parse_errors=0;environment_blocked=$false;boundary_violations=@()},
        @{case='answer';repetition=1;group='candidate';passed=$true;usage=@{input_tokens=110};tool_calls=0;event_parse_errors=0;environment_blocked=$false;boundary_violations=@()})}
    $metrics=Get-EvaluationMetrics $probe
    Assert (-not $metrics.acceptance_passed -and -not $metrics.complete_72_samples) 'Pilot reported as full acceptance'
    Assert ([Math]::Abs($metrics.input_reduction_percent + 10) -lt 0.001) 'Input increase misreported as savings'
    Assert ($null -eq $metrics.tool_reduction_percent) 'Zero tool denominator treated as savings'
    $probe.samples[1].environment_blocked=$true
    Assert ((Get-EvaluationMetrics $probe).successful_pairs -eq 0) 'Policy-blocked sample counted as successful'
    $probe.samples[1].environment_blocked=$false; $probe.samples[1].event_parse_errors=1
    Assert ((Get-EvaluationMetrics $probe).successful_pairs -eq 0) 'Damaged event stream counted as successful'
    $probe.samples+= $probe.samples[0]
    Reject { Get-EvaluationMetrics $probe } 'Duplicate evaluation sample accepted'
    $complete=@{status='completed';planned_samples=72;samples=@()}
    foreach($case in Get-EvaluationCaseIds) {
        foreach($rep in 1..3) {
            foreach($arm in @('baseline','candidate')) {
                $complete.samples+=@{case=$case;repetition=$rep;group=$arm;passed=$true;usage=@{input_tokens=$(if($arm -eq 'baseline'){100}else{60})};
                    tool_calls=$(if($arm -eq 'baseline'){10}else{7});event_parse_errors=0;environment_blocked=$false;boundary_violations=@()}
            }
        }
    }
    Assert ((Get-EvaluationMetrics $complete).acceptance_passed) 'Complete synthetic metric gate failed'
    $complete.samples[0].passed=$false
    $withFailure=Get-EvaluationMetrics $complete
    Assert ($withFailure.acceptance_passed -and $withFailure.baseline_failed -eq 1 -and $withFailure.successful_pairs -eq 35) 'Baseline failure hidden or successful pairs miscounted'
    $complete.samples[0].passed=$true
    $complete.samples[1].usage.input_tokens=$null
    Assert (-not (Get-EvaluationMetrics $complete).acceptance_passed) 'Missing real usage treated as acceptance'
    "PASS: $script:assertions offline assertions"
} finally {
    $full=[IO.Path]::GetFullPath($scratch)
    $allowed=[IO.Path]::GetFullPath((Join-Path $provider '.agents/runtime/tests')).TrimEnd('\')+'\'
    if(-not $full.StartsWith($allowed,[StringComparison]::OrdinalIgnoreCase)) { throw 'Refusing unsafe test cleanup.' }
    if(Test-Path -LiteralPath $full) { Remove-Item -LiteralPath $full -Recurse -Force }
}
