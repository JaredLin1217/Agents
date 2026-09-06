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
        Assert (-not [IO.File]::ReadAllText((Join-Path $root '.agents/managed.json')).Contains("`r")) 'Manifest must use portable LF bytes'
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
        Assert ($before -eq (Get-SourceDigest $root (Get-AgentFiles $root))) 'Rollback did not restore all original target files'
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
    $unborn=Join-Path $scratch 'unborn repository'
    [IO.Directory]::CreateDirectory($unborn)|Out-Null
    $null=Invoke-AgentGit $unborn @('init','-q')
    $null=Deploy $unborn 'root-layout'
    $validator=Get-AgentAsset $unborn 'scripts/validate.ps1'
    foreach($profile in @('Checkpoint','Changed')) {
        $out=@(& pwsh -NoProfile -File $validator -Scope Consumer -Profile $profile -Json 2>&1)
        Assert ($LASTEXITCODE -eq 0) "Unborn $profile failed: $($out -join ' ')"
        $report=($out -join "`n")|ConvertFrom-Json -AsHashtable
        Assert ($report.paths -contains 'AGENTS.md') 'Unborn validation skipped untracked rules'
    }
    Put $unborn 'AGENTS.md' "Staged whitespace   `n"
    $null=Invoke-AgentGit $unborn @('add','AGENTS.md')
    [IO.File]::Copy((Join-Path $provider 'AGENTS.md'),(Join-Path $unborn 'AGENTS.md'),$true)
    $out=@(& pwsh -NoProfile -File $validator -Scope Consumer -Profile Changed -Json 2>&1)
    $report=($out -join "`n")|ConvertFrom-Json -AsHashtable
    Assert (($report.checks|Where-Object id -EQ 'diff').result -eq 'failed') 'Unborn validation missed staged whitespace'
    Assert (-not $report.passed) 'Unborn staged error reported success'
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
    "PASS: $script:assertions offline assertions"
} finally {
    $full=[IO.Path]::GetFullPath($scratch)
    $allowed=[IO.Path]::GetFullPath((Join-Path $provider '.agents/runtime/tests')).TrimEnd('\')+'\'
    if(-not $full.StartsWith($allowed,[StringComparison]::OrdinalIgnoreCase)) { throw 'Refusing unsafe test cleanup.' }
    if(Test-Path -LiteralPath $full) { Remove-Item -LiteralPath $full -Recurse -Force }
}
