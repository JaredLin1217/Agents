#requires -Version 7.0
param()
. "$PSScriptRoot/../scripts/agent-checks.ps1"
. "$PSScriptRoot/../scripts/agent-tasks.ps1"
. "$PSScriptRoot/../scripts/agent-deployment.ps1"
$provider=Get-AgentRoot;$assertions=0;$success=$false;$failure=''
$testRun=New-AgentRun $provider 'Agents v4 contracts' 'test-v4'
$fixtures=Register-AgentArtifact $provider $testRun.id "$($testRun.path)/fixtures" 'scratch' 'Disposable v4 contract fixtures'
$diagnostics=Register-AgentArtifact $provider $testRun.id "$($testRun.path)/diagnostics" 'validation' 'v4 assertion result and failures'
$scratch=Resolve-SafePath $provider $fixtures.path
$t0=[DateTimeOffset]::Parse('2026-10-08T00:00:00Z')
function Assert($Condition,[string]$Message) { if(-not $Condition){throw $Message};$script:assertions++ }
function Reject([scriptblock]$Action,[string]$Message) { $rejected=$false;try{$null=& $Action}catch{$rejected=$true};Assert $rejected $Message }
function Put([string]$Root,[string]$Path,[string]$Text) {
    $p=Resolve-SafePath $Root $Path;[IO.Directory]::CreateDirectory((Split-Path -Parent $p))|Out-Null
    [IO.File]::WriteAllText($p,$Text,[Text.UTF8Encoding]::new($false))
}
function Fixture([string]$Name,[string]$Layout='root-layout') {
    $root=Join-Path $scratch $Name;[IO.Directory]::CreateDirectory($root)|Out-Null
    $null=Invoke-AgentGit $root @('init','-q');$null=Invoke-AgentGit $root @('config','user.name','Disposable Test')
    $null=Invoke-AgentGit $root @('config','user.email','test@example.invalid')
    Put $root '.gitignore' ".agents/runtime/`n";Put $root 'contract.txt' 'verified contract'
    $null=Invoke-AgentGit $root @('add','.');$null=Invoke-AgentGit $root @('commit','-qm','fixture')
    $plan=Get-DeploymentPlan $provider $root $Layout;$null=Invoke-Deployment $provider $root $Layout $plan.plan_digest
    return $root
}
function Draft([string]$Root) {
    $run=New-AgentRun $Root 'Fixture drafts' 'test-v4'
    $entry=Register-AgentArtifact $Root $run.id "$($run.path)/drafts" 'scratch' 'Reviewed fixture proposals'
    return $entry.path
}
function Entry([string]$Root,[string]$Id,[string]$Key='contract') {
    $entry=Read-AgentJson (Join-Path $provider 'docs/templates/knowledge-entry.json')
    $entry.id=$Id;$entry.key=$Key;$entry.scope='fixture';$entry.conclusion='Verified contract survives reviewed recovery'
    $entry.modules=@('engine');$entry.tags=@('recovery');$entry.files=@('contract.txt')
    $entry.sources[0].path='contract.txt';$entry.sources[0].sha256=Get-AgentHash (Join-Path $Root 'contract.txt')
    $entry.sources[0].commit=[string](Invoke-AgentGit $Root @('rev-parse','HEAD'));$entry.sources[0].locator='Fixture contract'
    $entry.verified_utc=$t0.ToString('o');$entry.verification=@{method='Fixture hash and semantic assertion';summary='Review this test contract';result='passed';reviewed_by='offline test'}
    return $entry
}
function Publish([string]$Root,[string]$DraftPath,$Value,[string]$Action='Promote') {
    Write-AgentJson (Resolve-SafePath $Root "$DraftPath/input.json") $Value -Root $Root
    Publish-ProjectKnowledge $Root "$DraftPath/input.json" $Action -Automatic
}
function TaskInput([string]$Id) {
    $inputData=Read-AgentJson (Join-Path $provider 'docs/templates/task-input.json')
    $inputData.id=$Id;$inputData.objective='Finish the verified fixture';$inputData.latest_adjustment='Keep current authorized requirements'
    $inputData.boundaries=@('contract.txt');$inputData.acceptance_criteria=@('Current contract verified')
    return $inputData
}
function Receipt([string]$Root) {
    $run=New-AgentRun -Root $Root -Purpose 'Fixture receipt' -Now $t0
    $artifact=Register-AgentArtifact $Root $run.id "$($run.path)/validation" 'validation' 'Source-bound fixture receipt'
    $path="$($artifact.path)/report.json"
    $report=@{schema_version='agents-validation/v4';run_id=$run.id;receipt_path=$path;started_utc=$t0.ToString('o');finished_utc=$t0.ToString('o');scope='Consumer';profile='Changed';input_digest=(Get-TextHash 'contract');paths=@('contract.txt');host=@{powershell='offline';git='offline'};
        checks=@(@{id='fixture';command='offline fixture assertion';result='passed';exit_code=0;duration_ms=0;retry_count=0;details=@()});result='passed';passed=$true;release_ready=$false;require_release_ready=$false}
    Write-AgentJson (Resolve-SafePath $Root $path) $report -Root $Root;$null=Complete-AgentRun -Root $Root -RunId $run.id -Now $t0
    return @{reference=@{path=$path;sha256=(Get-AgentHash (Resolve-SafePath $Root $path));input_digest=$report.input_digest;result='passed'};artifact=$artifact}
}
try {
    $empty=Join-Path $scratch 'empty runtime';[IO.Directory]::CreateDirectory($empty)|Out-Null
    Assert ((Get-RuntimeInventory $empty).artifacts.Count -eq 0) 'Empty inventory returned a phantom artifact'
    $root=Fixture 'inventory-scale';$run=New-AgentRun $root 'Nested inventory fixture'
    $artifact=Register-AgentArtifact $root $run.id "$($run.path)/payload" 'scratch' 'Many nested owned paths'
    for($i=0;$i -lt 256;$i++) { Put $root "$($artifact.path)/nested/$i/file.txt" "owned-$i" }
    $null=Complete-AgentRun $root $run.id
    $compact=Get-RuntimeInventory $root;$expanded=Get-RuntimeInventory $root -Expand
    Assert ($compact.unknown.Count -eq 0 -and $compact.issues.Count -eq 0) 'Nested owned inventory was misclassified'
    Assert (-not $compact.artifacts[0].Contains('items') -and $expanded.artifacts[0].Contains('items')) 'Inventory expansion boundary failed'
    $actual=Get-RuntimeFootprint $root $artifact.path
    $expected=@(Get-ChildItem -LiteralPath (Resolve-SafePath $root $artifact.path) -Recurse -Force|ForEach-Object {
        [ordered]@{path=[IO.Path]::GetRelativePath($root,$_.FullName).Replace('\','/');kind=$(if($_.PSIsContainer){'directory'}else{'file'});sha256=$(if($_.PSIsContainer){''}else{Get-AgentHash $_.FullName})}
    })+@([ordered]@{path=$artifact.path;kind='directory';sha256=''})
    $expected=@($expected|Sort-Object { $_.path })
    Assert ($actual.digest -eq (Get-TextHash ($expected|ConvertTo-Json -Depth 8 -Compress))) 'Optimized footprint changed the recorded hash contract'
    $legacyRecord=@($expanded.artifacts|Where-Object id -EQ $artifact.id)[0];$legacyRecord.items=@($actual.items|Sort-Object { $_.path } -Descending)
    $legacyRecord.sha256=Get-TextHash ($legacyRecord.items|ConvertTo-Json -Depth 8 -Compress)
    Write-AgentJson (Get-RuntimePath $root "ledger/artifacts/$($legacyRecord.id).json") $legacyRecord -Root $root
    $expiry=[DateTimeOffset]::Parse($legacyRecord.expires_utc)
    $legacyPlan=Get-RuntimeCleanupPlan $root $expiry
    Assert ($artifact.id -in $legacyPlan.candidates.id -and $legacyPlan.blocked.Count -eq 0) 'Verified historical traversal digest was not accepted'
    Put $root "$($artifact.path)/nested/0/file.txt" 'changed'
    Assert ((Get-RuntimeCleanupPlan $root $expiry).blocked.Count -gt 0) 'Historical digest compatibility accepted changed bytes'
    Put $root "$($artifact.path)/nested/0/file.txt" 'owned-0'
    $null=Invoke-RuntimeCleanup $root $legacyPlan $legacyPlan.digest $expiry
    Assert (-not(Test-Path -LiteralPath (Resolve-SafePath $root $artifact.path))) 'Historical digest cleanup did not leave a tombstone'
    $root=Fixture 'knowledge';$draft=Draft $root;$entry=Entry $root 'K1'
    Publish $root $draft $entry
    $recall=Get-ProjectKnowledge $root -Query @('contract','recovery') -Module engine -Tag recovery -File contract.txt
    Assert ($recall.entries.Count -eq 1 -and $recall.entries[0].query_hits -eq 2) 'Multi-query/filter recall failed'
    Assert (-not $recall.entries[0].Contains('sources')) 'Summary eagerly expanded sources'
    Assert ((Get-ProjectKnowledge $root -Expand).entries[0].sources[0].kind -eq 'file_snapshot') 'Source expansion failed'
    Assert ((Get-ProjectKnowledge $root -Module unrelated).entries.Count -eq 0) 'Module filter ignored'
    Reject { Publish $root $draft $entry } 'Immutable record overwritten'
    $entry.id='K2';$entry.supersedes=@('K1');Put $root 'contract.txt' 'revised contract'
    Assert ((Get-ProjectKnowledge $root).entries.Count -eq 0) 'Changed source recalled'
    $entry.sources[0].sha256=Get-AgentHash (Join-Path $root 'contract.txt');$entry.freshness.review_after_utc=$t0.AddDays(1).ToString('o')
    Publish $root $draft $entry
    Assert ((Get-ProjectKnowledge $root -Now $t0.AddDays(1).AddTicks(-1)).entries.id -eq 'K2') 'Freshness boundary suppressed early'
    Assert ((Get-ProjectKnowledge $root -Now $t0.AddDays(1)).entries.Count -eq 0) 'Expired replacement recalled/resurrected'
    $entry.id='R1';$entry.status='retracted';$entry.supersedes=@();$entry.retracts=@('K2');$entry.freshness.review_after_utc=$null
    Publish $root $draft $entry 'Retract'
    Assert ((Get-ProjectKnowledge $root).entries.Count -eq 0) 'Retraction revived old fact'
    $entry=Entry $root 'D1' 'duplicate';Publish $root $draft $entry
    $entry.id='D2';Publish $root $draft $entry
    $conflict=Get-ProjectKnowledge $root
    Assert ($conflict.entries.Count -eq 0 -and $conflict.gaps.Count -gt 0) 'Duplicate active key did not pause recall'
    $entry.id='D3';$entry.supersedes=@('D1','D2');Publish $root $draft $entry
    Assert ((Get-ProjectKnowledge $root).entries.id -eq 'D3') 'Explicit conflict resolution failed'
    Write-AgentJson (Resolve-SafePath $root 'docs/memory/entries/duplicate-id.json') $entry -Root $root
    Assert ((Get-ProjectKnowledge $root).entries.Count -eq 0) 'Duplicate ID recalled'
    Remove-Item -LiteralPath (Resolve-SafePath $root 'docs/memory/entries/duplicate-id.json')
    $entry.id='bad';$entry.sources[0].path="$draft/input.json";$entry.sources[0].sha256=Get-AgentHash (Resolve-SafePath $root "$draft/input.json")
    Reject { Publish $root $draft $entry } 'Temporary-only knowledge promoted'
    $entry=Entry $root 'sensitive';$entry.sensitive=$true
    Reject { Publish $root $draft $entry } 'Sensitive knowledge promoted'
    Reject { & (Get-AgentAsset $root 'scripts/project-memory.ps1') -Action Promote -Root $root -InputPath "$draft/input.json" -ReadOnly } 'ReadOnly promotion allowed'
    Put $root 'docs/memory/entries/broken.json' '{broken'
    Assert ((Get-ProjectKnowledge $root).entries.Count -eq 0) 'Unreadable retirement graph did not stop recall'
    Remove-Item -LiteralPath (Resolve-SafePath $root 'docs/memory/entries/broken.json')
    $entry=Entry $root 'C1' 'cycle';$entry.supersedes=@('C2');Write-AgentJson (Resolve-SafePath $root 'docs/memory/entries/C1.json') $entry -Root $root
    $entry.id='C2';$entry.supersedes=@('C1');Write-AgentJson (Resolve-SafePath $root 'docs/memory/entries/C2.json') $entry -Root $root
    Assert ((Get-ProjectKnowledge $root).gaps.Count -gt 0) 'Broken/cyclic chain accepted'

    $root=Fixture 'provenance';$draft=Draft $root
    $legacy=Read-AgentJson (Join-Path $provider 'docs/memory/entries/M001-semantic-intent.json');$legacy.id='legacy';$legacy.sources[0].path='contract.txt';$legacy.sources[0].sha256=Get-AgentHash (Join-Path $root 'contract.txt');$legacy.verified_utc=$t0.ToString('o')
    Write-AgentJson (Resolve-SafePath $root 'docs/memory/entries/legacy.json') $legacy -Root $root
    $before=Get-AgentHash (Resolve-SafePath $root 'docs/memory/entries/legacy.json')
    $entry=Entry $root 'migrated';$entry.supersedes=@('legacy');Publish $root $draft $entry 'Migrate'
    Assert ((Get-AgentHash (Resolve-SafePath $root 'docs/memory/entries/legacy.json')) -eq $before) 'Migration altered old record'
    Assert ((Get-ProjectKnowledge $root).entries.id -eq 'migrated') 'v3 migration did not retire original'
    Put $root 'decision.md' 'Explicit fixture decision: preserve contract'
    $entry=Entry $root 'decision' 'decision';$entry.type='decision';$entry.sources=@(@{kind='user_decision';path='decision.md';sha256=(Get-AgentHash (Join-Path $root 'decision.md'));locator='Explicit fixture decision';explicit=$true})
    Publish $root $draft $entry
    Assert ((Get-ProjectKnowledge $root -Expand).entries.sources.kind -contains 'user_decision') 'User decision provenance missing'
    $entry.id='unapproved';$entry.sources[0].explicit=$false;Reject { Publish $root $draft $entry } 'Implicit decision promoted'
    $entry=Entry $root 'official' 'official';$entry.sources=@(@{kind='official_document';url='https://learn.chatgpt.com/docs/hooks.md';snapshot_path='decision.md';sha256=(Get-AgentHash (Join-Path $root 'decision.md'));content_sha256=(Get-TextHash 'offline');locator='Fixture snapshot';checked_utc=$t0.ToString('o');review_after_utc=$t0.AddDays(1).ToString('o')})
    Write-AgentJson (Resolve-SafePath $root "$draft/official.json") $entry -Root $root
    Reject { Publish-ProjectKnowledge $root "$draft/official.json" 'Promote' -Automatic } 'Automatic official promotion skipped live review'
    Write-AgentJson (Resolve-SafePath $root 'docs/memory/entries/official.json') $entry -Root $root
    Assert ((Get-ProjectKnowledge $root -Query official -Now $t0.AddDays(1)).entries.Count -eq 0) 'Expired official source recalled'

    $root=Fixture 'tasks';$draft=Draft $root;$inputData=TaskInput 'T1'
    $inputData.external_actions=@(@{id='observed';action='Observed fixture operation';status='completed';observed_utc=$t0.ToString('o');evidence='Fixture operation already completed; no replay'})
    $saved=Save-AgentTask $root $inputData 0
    Assert ($saved.checkpoint.revision -eq 1 -and -not $saved.requires_reinspection) 'New task revision incorrect'
    Reject { Save-AgentTask $root $inputData 0 } 'Concurrent expected revision overwrite accepted'
    $lock=Enter-RuntimeLock $root 'task-T1'
    try { Reject { Save-AgentTask $root $inputData 1 } 'Concurrent task lock bypassed' } finally { Exit-RuntimeLock $lock }
    $inputData.objective='User revised the fixture outcome';$inputData.latest_adjustment='New acceptance condition';$inputData.acceptance_criteria+=@('Retain requirement history')
    $saved=Save-AgentTask $root $inputData 1
    Assert ($saved.checkpoint.requirements.Count -eq 2 -and $saved.checkpoint.requirements[0].objective -eq 'Finish the verified fixture') 'Latest goal/history lost'
    $inputData.external_actions[0].status='planned';Reject { Save-AgentTask $root $inputData 2 } 'Completed external operation rewritten'
    $inputData.external_actions[0].status='completed'
    $null=Invoke-AgentGit $root @('add','contract.txt')
    # Add a new index-only record without changing the checkpoint boundary bytes.
    Put $root 'index-only.txt' 'staged change';$null=Invoke-AgentGit $root @('add','index-only.txt')
    $resumed=Resume-AgentTask $root 'T1'
    Assert ($resumed.requires_reinspection -and $resumed.changed_files.Count -eq 0) 'Index change was not detected'
    Assert ($resumed.checkpoint.external_actions[0].status -eq 'completed') 'Resume lost completed operation evidence'
    $null=Invoke-AgentGit $root @('commit','-qm','index and head change')
    Assert ((Resume-AgentTask $root 'T1').current_commit -ne $saved.checkpoint.git.head -and (Resume-AgentTask $root 'T1').requires_reinspection) 'HEAD change not detected'
    Put $root 'contract.txt' 'changed boundary'
    Assert ((Resume-AgentTask $root 'T1').changed_files -contains 'contract.txt') 'Boundary change not detected'
    $input2=TaskInput 'T2';$null=Save-AgentTask $root $input2 0
    $candidateReport=Resume-AgentTask $root
    Assert ($candidateReport.selection_required -and $candidateReport.candidates.Count -eq 2) 'Multiple tasks guessed newest'
    Write-AgentJson (Resolve-SafePath $root "$draft/task.json") $inputData -Root $root
    Reject { & (Get-AgentAsset $root 'scripts/task-state.ps1') -Action Save -Root $root -InputPath "$draft/task.json" } 'CLI save accepted missing expected revision'
    Reject { & (Get-AgentAsset $root 'scripts/task-state.ps1') -Action Save -Root $root -InputPath "$draft/task.json" -ExpectedRevision 2 -ReadOnly } 'ReadOnly task mutated'
    $oldTask=@{schema_version='agents-task/v3';id='old-task';objective='Legacy objective';latest_adjustment='Legacy adjustment';boundaries=@('contract.txt');completed=@();open_issues=@();next_steps=@('Reinspect');source_commit=[string](Invoke-AgentGit $root @('rev-parse','HEAD'));updated_utc=$t0.ToString('o');files=@(@{path='contract.txt';sha256=(Get-AgentHash (Join-Path $root 'contract.txt'))})}
    Write-AgentJson (Get-RuntimePath $root 'tasks/old-task.json') $oldTask -Root $root
    Assert ((Resume-AgentTask $root 'old-task').legacy) 'v3 task not readable'
    $oldHash=Get-AgentHash (Get-RuntimePath $root 'tasks/old-task.json');$migration=TaskInput 'old-task'
    Reject { Save-AgentTask $root $migration 0 } 'Legacy state overwritten without migration'
    $migrated=Save-AgentTask $root $migration 0 -Migrate
    Assert ($migrated.checkpoint.schema_version -eq 'agents-task/v4' -and (Get-AgentHash (Resolve-SafePath $root $migrated.checkpoint.migrated_from.archived_path)) -eq $oldHash -and -not(Test-Path -LiteralPath (Get-RuntimePath $root 'tasks/old-task.json'))) 'Task migration did not preserve original bytes in registered provenance'
    $recoveryInput=TaskInput 'pointer-recovery';$null=Save-AgentTask $root $recoveryInput 0
    $pointerPath=Get-RuntimePath $root 'state/tasks/pointer-recovery.json';$pointer=Read-AgentJson $pointerPath
    Remove-Item -LiteralPath $pointerPath
    Assert ((Resume-AgentTask $root 'pointer-recovery').status -eq 'recovery_or_retired') 'Interrupted pointer trusted legacy or lost history'
    Assert ('pointer-recovery' -in (Get-AgentIds @(Get-TaskCandidates $root))) 'Interrupted task omitted from candidate list'
    Reject { Save-AgentTask $root $recoveryInput 0 } 'Interrupted task overwritten as new'
    $reconciled=Repair-AgentTaskPointer $root 'pointer-recovery' $pointer.path 0 $pointer.sha256 'Fixture pointer recovery'
    Assert ($reconciled.checkpoint.revision -eq 1) 'Task pointer recovery failed'
    $recoveryInput.open_issues=@('Not resolved');Reject { Save-AgentTask $root $recoveryInput 1 -Complete } 'Task with unresolved issues completed'

    $root=Fixture 'retention';$draft=Draft $root;$receipt=Receipt $root;$inputData=TaskInput 'retained-task'
    $inputData.validation_receipts=@($receipt.reference)
    $saved=Save-AgentTask -Root $root -InputData $inputData -ExpectedRevision 0 -Now $t0
    $inputData.next_steps=@();$completed=Save-AgentTask -Root $root -InputData $inputData -ExpectedRevision 1 -Complete -Now $t0.AddDays(1)
    Assert ($completed.checkpoint.status -eq 'completed') 'Task completion failed'
    $plan=Get-RuntimeCleanupPlan $root $t0.AddDays(31)
    Assert ($receipt.artifact.id -notin (Get-AgentIds $plan.candidates)) 'Task receipt expired before its dependent checkpoint'
    $pointer=Read-AgentJson (Get-RuntimePath $root 'state/tasks/retained-task.json')
    Assert ($pointer.artifact_id -notin (Get-AgentIds (Get-RuntimeCleanupPlan $root $t0.AddDays(91).AddTicks(-1)).candidates)) 'Task expired before 90 days'
    $plan=Get-RuntimeCleanupPlan $root $t0.AddDays(91)
    Assert ($pointer.artifact_id -in (Get-AgentIds $plan.candidates)) 'Task did not expire at 90-day boundary'
    $null=Invoke-RuntimeCleanup $root $plan $plan.digest $t0.AddDays(91)
    Assert (@(Get-TaskCandidates $root).Count -eq 0) 'Expired completed pointer retained'
    Assert ($receipt.artifact.id -in (Get-AgentIds (Get-RuntimeCleanupPlan $root $t0.AddDays(91)).candidates)) 'Retired task kept receipt pinned forever'
    Reject { Save-AgentTask $root $inputData 0 } 'Deleted task ID was silently reused'

    foreach($category in @('scratch','package','validation')) {
        $root=Fixture "ttl-$category";$run=New-AgentRun -Root $root -Purpose 'Boundary retention fixture' -Now $t0
        $artifact=Register-AgentArtifact $root $run.id "$($run.path)/payload" $category 'Known fixture payload'
        Put $root "$($artifact.path)/payload.txt" 'owned';$null=Complete-AgentRun -Root $root -RunId $run.id -Now $t0
        $days=if($category -eq 'validation'){30}else{7};$deadline=$t0.AddDays($days)
        Assert ($artifact.id -notin (Get-AgentIds (Get-RuntimeCleanupPlan $root $deadline.AddTicks(-1)).candidates)) "$category expired early"
        $plan=Get-RuntimeCleanupPlan $root $deadline;Assert ($artifact.id -in (Get-AgentIds $plan.candidates)) "$category deadline missing"
        $roundtrip=$plan|ConvertTo-Json -Depth 30|ConvertFrom-Json -AsHashtable -DateKind String
        $null=Invoke-RuntimeCleanup $root $roundtrip $plan.digest $deadline
        Assert (-not(Test-Path -LiteralPath (Resolve-SafePath $root $artifact.path))) "$category not deleted"
        $tombstone=Read-AgentJson (Get-RuntimePath $root "ledger/artifacts/$($artifact.id).json")
        Assert ($tombstone.status -eq 'deleted' -and $tombstone.sha256) 'Deletion provenance missing'
        Assert (@(Get-ChildItem -LiteralPath (Get-RuntimePath $root 'ledger/events') -File|Where-Object { (Read-AgentJson $_.FullName).action -eq 'deleted' }).Count -gt 0) 'Deletion event missing'
    }
    $root=Fixture 'cleanup-guards';$run=New-AgentRun -Root $root -Purpose 'Cleanup guard fixture' -Now $t0
    $artifact=Register-AgentArtifact $root $run.id "$($run.path)/payload" 'scratch' 'Guarded payload'
    Put $root "$($artifact.path)/data.txt" 'original';$null=Complete-AgentRun -Root $root -RunId $run.id -Now $t0
    $plan=Get-RuntimeCleanupPlan $root $t0.AddDays(7)
    Put $root "$($artifact.path)/data.txt" 'changed'
    Reject { Invoke-RuntimeCleanup $root $plan $plan.digest $t0.AddDays(7) } 'Changed hash cleanup accepted'
    Assert ((Get-RuntimeCleanupPlan $root $t0.AddDays(7)).blocked.Count -gt 0) 'Hash mutation not reported'
    Put $root "$($artifact.path)/data.txt" 'original';Put $root "$($artifact.path)/unknown.txt" 'unknown'
    Reject { Invoke-RuntimeCleanup $root $plan $plan.digest $t0.AddDays(7) } 'Unknown child deleted'
    Remove-Item -LiteralPath (Resolve-SafePath $root "$($artifact.path)/unknown.txt")
    $empty=Resolve-SafePath $root "$($run.path)/unregistered-empty";[IO.Directory]::CreateDirectory($empty)|Out-Null
    Reject { Invoke-RuntimeCleanup $root $plan $plan.digest $t0.AddDays(7) } 'Unknown empty folder cleanup accepted'
    [IO.Directory]::Delete($empty,$false)
    Put $root '.agents/runtime/unknown.txt' 'unknown legacy data'
    Assert ((Get-RuntimeCleanupPlan $root $t0.AddDays(7)).blocked.Count -gt 0) 'Unknown runtime data not reported'
    Reject { Invoke-RuntimeCleanup $root $plan $plan.digest $t0.AddDays(7) } 'Unknown runtime data bypassed'
    Remove-Item -LiteralPath (Get-RuntimePath $root 'unknown.txt')
    $link=Resolve-SafePath $root "$($artifact.path)/linked"
    $null=New-Item -ItemType Junction -Path $link -Target (Join-Path $scratch 'knowledge')
    try { Reject { Invoke-RuntimeCleanup $root $plan $plan.digest $t0.AddDays(7) } 'Linked cleanup accepted' } finally { Remove-Item -LiteralPath $link }
    $lock=Enter-RuntimeLock $root 'deployment'
    try { Reject { Invoke-RuntimeCleanup $root $plan $plan.digest $t0.AddDays(7) } 'Deployment lock bypassed' } finally { Exit-RuntimeLock $lock }
    $lock=Enter-RuntimeLock $root
    try { Assert ((Get-RuntimeCleanupPlan $root $t0.AddDays(7)).blocked.Count -gt 0) 'Runtime lock not reported' } finally { Exit-RuntimeLock $lock }
    $altered=Read-AgentJson (Get-RuntimePath $root "ledger/artifacts/$($artifact.id).json");$altered.retain_reasons=@('rollback dependency')
    Write-AgentJson (Get-RuntimePath $root "ledger/artifacts/$($artifact.id).json") $altered -Root $root
    Reject { Invoke-RuntimeCleanup $root $plan $plan.digest $t0.AddDays(7) } 'New pin bypassed stale preview'
    Reject { & (Get-AgentAsset $root 'scripts/runtime-artifacts.ps1') -Action Retire -Root $root -Id $artifact.id -Reason 'Read-only test' -ReadOnly } 'ReadOnly runtime retired artifact'

    foreach($status in @('failed','interrupted')) {
        $root=Fixture "status-$status";$run=New-AgentRun -Root $root -Purpose 'Unresolved result fixture' -Now $t0
        $artifact=Register-AgentArtifact $root $run.id "$($run.path)/payload" 'scratch' 'Preserve unresolved state'
        Put $root "$($artifact.path)/result.txt" $status;$null=Complete-AgentRun -Root $root -RunId $run.id -Status $status -Now $t0
        Assert ($artifact.id -notin (Get-AgentIds (Get-RuntimeCleanupPlan $root $t0.AddDays(365)).candidates)) 'Unresolved work expired'
        Reject { Retire-AgentArtifact $root $artifact.id '' } 'Failure retirement omitted reason'
        $retired=Retire-AgentArtifact $root $artifact.id 'Fixture explicitly resolved' $t0.AddDays(1)
        Assert ($retired.expires_utc -eq $t0.AddDays(8).ToString('o')) 'Retirement did not restart retention'
    }
    $root=Fixture 'dependencies';$run=New-AgentRun -Root $root -Purpose 'Dependency base' -Now $t0
    $base=Register-AgentArtifact $root $run.id "$($run.path)/base" 'scratch' 'Base dependency';$null=Complete-AgentRun -Root $root -RunId $run.id -Now $t0
    $dependentRun=New-AgentRun -Root $root -Purpose 'Dependent package' -Now $t0
    $dependent=Register-AgentArtifact -Root $root -RunId $dependentRun.id -Path "$($dependentRun.path)/package" -Category package -Purpose 'Requires base' -Dependencies @($base.id)
    $null=Complete-AgentRun -Root $root -RunId $dependentRun.id -Now $t0
    $plan=Get-RuntimeCleanupPlan $root $t0.AddDays(7)
    Assert ($base.id -notin (Get-AgentIds $plan.candidates) -and $dependent.id -in (Get-AgentIds $plan.candidates)) 'Dependency cleanup order unsafe'
    $null=Invoke-RuntimeCleanup $root $plan $plan.digest $t0.AddDays(7)
    Assert ($base.id -in (Get-AgentIds (Get-RuntimeCleanupPlan $root $t0.AddDays(7)).candidates)) 'Dependency never released'
    $childRun=New-AgentRun $root 'Child environment fixture';$before=$env:TEMP
    $inherited=Invoke-AgentChild $root $childRun.id { (& pwsh -NoProfile -Command '$env:TEMP') }
    Assert ($inherited -like "*runs*$($childRun.id)*child-temp*" -and $env:TEMP -eq $before) 'Child temp scope leaked'
    $null=Complete-AgentRun $root $childRun.id

    $root=Fixture 'backup-retirement';$pointerFile=@(Get-ChildItem -LiteralPath (Get-RuntimePath $root 'ledger/deployments') -File)[0]
    $pointer=Read-AgentJson $pointerFile.FullName;$transaction=$pointerFile.BaseName
    $journalPath=Get-DeploymentJournalPath $root $transaction;$journal=Read-AgentJson $journalPath
    $journal.status='applying';Write-AgentJson $journalPath $journal -Root $root
    Reject { Retire-AgentArtifact $root $pointer.artifact_id 'Unresolved transaction' } 'Interrupted backup retired'
    $null=Restore-Deployment $root $transaction
    $retired=Retire-AgentArtifact $root $pointer.artifact_id 'Fixture rollback completed; dependency retired' $t0
    Assert ($retired.retain_reasons.Count -eq 0) 'Resolved backup did not retire'
    $plan=Get-RuntimeCleanupPlan $root $t0.AddDays(7);$null=Invoke-RuntimeCleanup $root $plan $plan.digest $t0.AddDays(7)
    $newPlan=Get-DeploymentPlan $provider $root 'root-layout'
    Assert ((Invoke-Deployment $provider $root 'root-layout' $newPlan.plan_digest).status -eq 'committed') 'Retired/deleted backup blocked future deployment'

    foreach($layout in @('root-layout','dot-agents-layout')) {
        $root=Fixture "$layout hooks 中文 空白" $layout;$draft=Draft $root;$inputData=TaskInput 'hook-task';$null=Save-AgentTask $root $inputData 0
        $inputData.objective='User revised hook task';$inputData.latest_adjustment='Preserve new goal across a new dialogue and compaction';$inputData.acceptance_criteria+=@('New hook acceptance condition')
        $null=Save-AgentTask $root $inputData 1
        Put $root 'contract.txt' 'Hook detects updated file';[IO.Directory]::CreateDirectory((Join-Path $root 'nested folder'))|Out-Null
        $hook=Get-AgentAsset $root 'scripts/project-hooks.ps1'
        $event=@{session_id='test session';turn_id='test turn';cwd=(Join-Path $root 'nested folder');hook_event_name='SessionStart';source='compact';permission_mode='plan';transcript_path='never-read-this.jsonl'}
        $before=(Get-RuntimeFootprint $root '.agents/runtime').digest
        $start=(& $hook -InputJson ($event|ConvertTo-Json -Compress))|ConvertFrom-Json -AsHashtable
        Assert ($start.hookSpecificOutput.hookEventName -eq 'SessionStart' -and $start.hookSpecificOutput.additionalContext -match 'hook-task') 'Compact SessionStart did not recall state'
        Assert ($start.hookSpecificOutput.additionalContext -match 'User revised hook task' -and $start.hookSpecificOutput.additionalContext -match 'New hook acceptance condition') 'New dialogue/compact lost revised requirements'
        Assert ((Get-RuntimeFootprint $root '.agents/runtime').digest -eq $before) 'Plan SessionStart wrote state'
        $event.hook_event_name='PreCompact';$compact=(& $hook -InputJson ($event|ConvertTo-Json -Compress))|ConvertFrom-Json -AsHashtable
        Assert ($compact.systemMessage -match 'checkpoint') 'PreCompact did not inspect checkpoint'
        $event.hook_event_name='Stop';$event.stop_hook_active=$false
        $stop=(& $hook -InputJson ($event|ConvertTo-Json -Compress))|ConvertFrom-Json -AsHashtable
        Assert (-not $stop.ContainsKey('decision') -and (Get-RuntimeFootprint $root '.agents/runtime').digest -eq $before) 'Plan Stop wrote/continued'
        $event.permission_mode='default'
        $stop=(& $hook -InputJson ($event|ConvertTo-Json -Compress))|ConvertFrom-Json -AsHashtable
        Assert ($stop.decision -eq 'block') 'Stop omitted single continuation'
        $repeat=(& $hook -InputJson ($event|ConvertTo-Json -Compress))|ConvertFrom-Json -AsHashtable
        Assert (-not $repeat.ContainsKey('decision')) 'Reentrant Stop repeated continuation'
        $event.turn_id='another-turn';$event.stop_hook_active=$true
        $stop=(& $hook -InputJson ($event|ConvertTo-Json -Compress))|ConvertFrom-Json -AsHashtable
        Assert (-not $stop.ContainsKey('decision')) 'stop_hook_active looped'
        $event.stop_hook_active=$false;$before=(Get-RuntimeFootprint $root '.agents/runtime').digest
        $stop=(& $hook -InputJson ($event|ConvertTo-Json -Compress) -ReadOnly)|ConvertFrom-Json -AsHashtable
        Assert (-not $stop.ContainsKey('decision') -and (Get-RuntimeFootprint $root '.agents/runtime').digest -eq $before) 'ReadOnly hook mutated state'
        $invalid=(& $hook -InputJson '{broken')|ConvertFrom-Json -AsHashtable
        Assert ($invalid.systemMessage -match 'could not inspect') 'Malformed event not visible'
        Assert (-not(Test-Path -LiteralPath (Join-Path $root '.codex/hooks.json'))) 'Template implicitly activated'
        $template=Read-AgentJson (Get-AgentAsset $root 'docs/templates/codex-hooks.json')
        $event.hook_event_name='SessionStart';$event.permission_mode='plan';$event.source='startup'
        Push-Location (Join-Path $root 'nested folder')
        try {
            $wire=($event|ConvertTo-Json -Compress)|& $env:ComSpec /d /s /c $template.hooks.SessionStart[0].hooks[0].commandWindows
            Assert ($LASTEXITCODE -eq 0) 'Windows template command failed'
            $wireData=($wire -join "`n")|ConvertFrom-Json -AsHashtable
            Assert ($wireData.hookSpecificOutput.hookEventName -eq 'SessionStart') 'Windows template stdin/event interface failed'
        } finally { Pop-Location }
    }
    # Missing-evidence tests use a disposable Provider, regardless of publication state here.
    $declaredEvidence=(Read-AgentJson (Join-Path $provider 'agents.json')).release_evidence
    $mirror=Fixture 'release-provider-fixture'
    # A disposable Provider with explicit regression sentinels exercises gate/collector integration without recursion.
    foreach($path in Get-AgentFiles $provider|Where-Object { $_ -notlike 'docs/memory/entries/*' -and $_ -ne $declaredEvidence }) {
        $dest=Resolve-SafePath $mirror $path;[IO.Directory]::CreateDirectory((Split-Path -Parent $dest))|Out-Null
        [IO.File]::Copy((Resolve-SafePath $provider $path),$dest,$true)
    }
    Remove-Item -LiteralPath (Resolve-SafePath $mirror '.agents/managed.json')
    Put $mirror 'tests/test-workflow.ps1' '"PASS: disposable gate sentinel"'
    Put $mirror 'tests/test-v4.ps1' '"PASS: disposable gate sentinel"'
    $null=Invoke-AgentGit $mirror @('add','.');$null=Invoke-AgentGit $mirror @('commit','-qm','disposable provider contracts')
    Assert ((Test-AgentEvidence $mirror).status -eq 'needs_review') 'Missing v4 evidence was marked passed'
    Assert ((Test-AgentEvidence $mirror -Capture).status -eq 'not_applicable') 'Capture nested its evidence gate'
    $gate=Invoke-AgentChecks -Root $mirror -Scope Provider -Profile Checkpoint -RequireReleaseReady
    Assert (-not $gate.passed -and -not $gate.release_ready -and ($gate.checks|Where-Object id -EQ 'evidence').result -eq 'needs_review') 'Missing evidence passed publication gate'
    Assert ($gate.checks.id -contains 'release-gate' -and (Test-Path -LiteralPath (Resolve-SafePath $mirror $gate.receipt_path))) 'Failed gate receipt missing'
    $out=@(& pwsh -NoProfile -File (Join-Path $mirror 'scripts/capture-runtime-evidence.ps1') 2>&1)
    Assert ($LASTEXITCODE -eq 0) "Disposable evidence collector failed: $($out -join ' ')"
    $evidencePath=(Read-AgentJson (Join-Path $mirror 'agents.json')).release_evidence
    $evidence=Read-AgentJson (Resolve-SafePath $mirror $evidencePath) (Join-Path $mirror 'schemas/release-evidence.schema.json')
    Assert ($evidence.schema_version -eq 'agents-runtime-evidence/v6' -and $evidence.result -eq 'passed') 'Collector did not bind v6 source evidence'
    Assert ((Test-AgentEvidence $mirror).status -eq 'passed') 'Generated committed-source evidence failed verification'
    $null=Invoke-AgentGit $mirror @('add',$evidencePath);$null=Invoke-AgentGit $mirror @('commit','-qm','evidence only')
    $gate=Invoke-AgentChecks -Root $mirror -Scope Provider -Profile Checkpoint -RequireReleaseReady
    Assert ($gate.passed -and $gate.release_ready) 'Matching committed-source evidence did not pass gate'
    $evidence.review_after_utc=$t0.AddDays(-1).ToString('o');Write-AgentJson (Resolve-SafePath $mirror $evidencePath) $evidence -Root $mirror
    Assert ((Test-AgentEvidence $mirror).status -eq 'needs_review') 'Expired evidence marked passed'
    $evidence.review_after_utc=[DateTimeOffset]::UtcNow.AddDays(30).ToString('o');Write-AgentJson (Resolve-SafePath $mirror $evidencePath) $evidence -Root $mirror
    Put $mirror 'contract.txt' 'mismatching source'
    Assert ((Test-AgentEvidence $mirror).status -eq 'needs_review') 'Mismatched source evidence passed'
    Put $mirror 'contract.txt' 'verified contract'
    $validEvidence=Read-AgentJson (Resolve-SafePath $mirror $evidencePath)
    $evidence.commands=@($evidence.commands|Where-Object id -NE 'regression-v4');Write-AgentJson (Resolve-SafePath $mirror $evidencePath) $evidence -Root $mirror
    Reject { Test-AgentEvidence $mirror } 'Incomplete evidence command set passed'
    Write-AgentJson (Resolve-SafePath $mirror $evidencePath) $validEvidence -Root $mirror
    $null=Invoke-AgentGit $mirror @('add',$evidencePath);$null=Invoke-AgentGit $mirror @('commit','-qm','fixture evidence refresh')
    # Legacy import must prove the entire catalog against a real local source commit.
    $packageId=[guid]::NewGuid().ToString('N');$legacyPath=".agents/runtime/packages/$packageId"
    $entries=@(Get-DeploymentEntries $mirror 'root-layout')
    foreach($file in $entries) {
        $dest=Resolve-SafePath $mirror "$legacyPath/$($file.path)";[IO.Directory]::CreateDirectory((Split-Path -Parent $dest))|Out-Null
        [IO.File]::Copy((Resolve-SafePath $mirror $file.source),$dest)
    }
    $manifest=@{schema_version='agents-managed/v3';version='4.0.0';layout='root-layout';files=$entries}
    Write-AgentJson (Resolve-SafePath $mirror "$legacyPath/.agents/managed.json") $manifest -Root $mirror
    Assert ((Get-LegacyPackageProof $mirror $manifest) -match '^[a-f0-9]{40}$') 'Known package origin not proven'
    $runtimeCli=Join-Path $mirror 'scripts/runtime-artifacts.ps1'
    Put $mirror "$legacyPath/unknown.txt" 'unknown'
    $digest=(Get-RuntimeFootprint $mirror $legacyPath).digest
    Reject { & $runtimeCli -Action Reconcile -Root $mirror -InputPath $legacyPath -ExpectedDigest $digest -Reason 'Fixture import' } 'Legacy unknown content imported'
    Remove-Item -LiteralPath (Resolve-SafePath $mirror "$legacyPath/unknown.txt")
    $digest=(Get-RuntimeFootprint $mirror $legacyPath).digest
    $import=(& $runtimeCli -Action Reconcile -Root $mirror -InputPath $legacyPath -ExpectedDigest $digest -Reason 'Fixture import')|ConvertFrom-Json -AsHashtable
    Assert (-not(Test-Path -LiteralPath (Resolve-SafePath $mirror $legacyPath)) -and (Test-Path -LiteralPath (Resolve-SafePath $mirror $import.destination))) 'Proven legacy migration failed'
    $manifest.files[0].sha256=Get-TextHash 'fabricated'
    Reject { Get-LegacyPackageProof $mirror $manifest } 'Fabricated manifest treated as source proof'
    # Atomic staging interruption is reconciled by its immutable start frame, never by filename alone.
    $root=Fixture 'staging';$cli=Get-AgentAsset $root 'scripts/runtime-artifacts.ps1';$writeId=[guid]::NewGuid().ToString('N')
    $stageRelative=".agents/runtime/state/staging/$writeId.tmp";Put $root $stageRelative 'owned stage'
    $start=Get-RuntimePath $root "ledger/writes/$writeId.start.json"
    Write-AgentJournalFrame $start @{schema_version='agents-write/v4';id=$writeId;phase='started';destination='contract.txt';staging=$stageRelative;sha256=(Get-TextHash 'owned stage');utc=$t0.ToString('o')}
    Assert ((Get-RuntimeCleanupPlan $root).blocked.Count -gt 0) 'Interrupted staging not reported'
    $reconciled=(& $cli -Action Reconcile -Root $root -Id $writeId -ExpectedDigest (Get-AgentHash $start) -Reason 'Fixture interrupted write')|ConvertFrom-Json -AsHashtable
    Assert ($reconciled.reconciled -eq $writeId -and -not(Test-Path -LiteralPath (Resolve-SafePath $root $stageRelative))) 'Interrupted staging not reconciled'
    $lock=Enter-RuntimeLock $root 'guard'
    try { Reject { & $cli -Action Reconcile -Root $root -Id lock-guard -ExpectedDigest (Get-TextHash 'unknown') -Reason 'Never remove running lock' } 'Running lock removed' } finally { Exit-RuntimeLock $lock }
    $run=New-AgentRun -Root $root -Purpose 'Interrupted deletion fixture' -Now $t0.AddDays(-8)
    $artifact=Register-AgentArtifact $root $run.id "$($run.path)/payload" 'scratch' 'Recover owned interrupted deletion'
    Put $root "$($artifact.path)/a.txt" 'a';Put $root "$($artifact.path)/b.txt" 'b';$null=Complete-AgentRun -Root $root -RunId $run.id -Now $t0.AddDays(-8)
    $record=Read-AgentJson (Get-RuntimePath $root "ledger/artifacts/$($artifact.id).json")
    Add-RuntimeEvent $root $artifact.id 'delete-started' @{path=$artifact.path;sha256=$record.sha256;plan_digest=(Get-TextHash 'interrupted fixture')}
    Remove-Item -LiteralPath (Resolve-SafePath $root "$($artifact.path)/a.txt")
    $reconciled=(& $cli -Action Reconcile -Root $root -Id $artifact.id -ExpectedDigest (Get-AgentHash (Get-RuntimePath $root "ledger/artifacts/$($artifact.id).json")) -Reason 'Finish verified interrupted deletion')|ConvertFrom-Json -AsHashtable
    Assert ($reconciled.status -eq 'deleted' -and -not(Test-Path -LiteralPath (Resolve-SafePath $root $artifact.path))) 'Interrupted deletion not reconciled'
    $root=Fixture 'fatal-receipt'
    $report=Invoke-AgentChecks -Root $root -Scope Consumer -Profile Changed -RequireReleaseReady
    Assert (-not $report.passed -and $report.checks.id -contains 'fatal') 'Invalid publication scope did not fail'
    Assert ((Test-Path -LiteralPath (Resolve-SafePath $root $report.receipt_path)) -and $report.result -eq 'failed') 'Fatal receipt was not saved'
    $savedReceipt=Read-AgentJson (Resolve-SafePath $root $report.receipt_path) (Get-AgentAsset $root 'schemas/validation-report.schema.json')
    Assert ($savedReceipt.checks[0].result -eq 'failed') 'Fatal saved receipt lied'
    $success=$true
    "PASS: $script:assertions v4 assertions; run=$($testRun.id)"
} catch { $failure=$_.Exception.ToString();throw }
finally {
    Write-AgentJson (Resolve-SafePath $provider "$($diagnostics.path)/result.json") @{passed=$success;assertions=$script:assertions;failure=$failure} -Root $provider
    $null=Complete-AgentRun $provider $testRun.id $(if($success){'completed'}else{'failed'})
}
