#requires -Version 7.4
param()
. "$PSScriptRoot/../scripts/agent-runtime.ps1"
. "$PSScriptRoot/../scripts/agent-deployment.ps1"
$provider=Get-AgentRoot;$assertions=0;$success=$false;$run=New-AgentRun $provider 'Agents v5 deployment layout and rollback tests' 'test-v5-deployment'
$artifact=Register-AgentArtifact $provider $run.id "$($run.path)/fixtures" 'scratch' 'Disposable v5 deployment fixtures'
$scratch=Resolve-SafePath $provider $artifact.path
function Assert($Condition,[string]$Message){if(-not $Condition){throw $Message};$script:assertions++}
function Reject([scriptblock]$Action,[string]$Message){$rejected=$false;try{$null=&$Action}catch{$rejected=$true};Assert $rejected $Message}
function Deploy([string]$Target,[string]$Layout,[string]$ProviderRoot=$provider) {
    $plan=Get-DeploymentPlan $ProviderRoot $Target $Layout
    Assert ($plan.conflicts.Count -eq 0) "Unexpected deployment conflict: $($plan.conflicts -join '; ')"
    $result=Invoke-Deployment $ProviderRoot $Target $Layout $plan.plan_digest
    return @{plan=$plan;result=$result}
}
try {
    $mirror=Join-Path $scratch 'provider-mirror';[IO.Directory]::CreateDirectory($mirror)|Out-Null
    foreach($sourcePath in @('agents.json','docs/agents/deployment.json','schemas/deployment.schema.json','schemas/managed.schema.json')) {
        $mirrorPath=Join-Path $mirror $sourcePath;[IO.Directory]::CreateDirectory((Split-Path -Parent $mirrorPath))|Out-Null
        [IO.File]::Copy((Resolve-SafePath $provider $sourcePath),$mirrorPath,$true)
    }
    foreach($entry in @(Get-DeploymentEntries $provider 'root-layout')) {
        $mirrorPath=Join-Path $mirror $entry.source;[IO.Directory]::CreateDirectory((Split-Path -Parent $mirrorPath))|Out-Null
        [IO.File]::Copy((Resolve-SafePath $provider $entry.source),$mirrorPath,$true)
    }
    $mirrorAgents=Join-Path $mirror 'AGENTS.md';$originalAgents=Get-Content -Raw (Resolve-SafePath $provider 'AGENTS.md')
    [IO.File]::WriteAllText($mirrorAgents,$originalAgents+"`n# disposable provider update`n",[Text.UTF8Encoding]::new($false))
    foreach($layout in @('root-layout','dot-agents-layout')) {
        $target=Join-Path $scratch ($layout+' 中文 空白')
        [IO.Directory]::CreateDirectory($target)|Out-Null
        [IO.File]::WriteAllText((Join-Path $target 'business.txt'),'preserve business data',[Text.UTF8Encoding]::new($false))
        $preview=Get-DeploymentPlan $provider $target $layout
        Assert ($preview.plan_digest -match '^[a-f0-9]{64}$' -and $preview.operations.Count -gt 1) "$layout dry-run missing operations"
        Reject { Invoke-Deployment $provider $target $layout 'bad-digest' } "$layout accepted an unreviewed digest"
        $first=Invoke-Deployment $provider $target $layout $preview.plan_digest
        Assert ($first.status -eq 'committed') "$layout deployment did not commit"
        $manifest=Read-AgentJson (Resolve-SafePath $target '.agents/managed.json') (Resolve-SafePath $provider 'schemas/managed.schema.json')
        Assert ($manifest.schema_version -eq 'agents-managed/v5' -and $manifest.layout -eq $layout) "$layout manifest contract invalid"
        foreach($entry in $manifest.files) { Assert ((Get-AgentHash (Resolve-SafePath $target $entry.path)) -eq $entry.sha256) "$layout deployed hash mismatch: $($entry.path)" }
        Assert ((Get-Content -Raw (Join-Path $target 'business.txt')) -eq 'preserve business data') "$layout touched business data"
        $repeat=Deploy $target 'auto'
        Assert ($repeat.result.status -eq 'unchanged') "$layout deployment was not idempotent"
        $validator=if($layout -eq 'root-layout'){Join-Path $target 'scripts/validate.ps1'}else{Join-Path $target '.agents/scripts/validate.ps1'}
        $consumer=@(& pwsh -NoProfile -File $validator -Root $target -Scope Consumer -Profile Changed -Json 2>&1)
        Assert ($LASTEXITCODE -eq 0) "$layout Consumer validation failed: $($consumer -join ' ')"
        $consumerReport=$consumer -join "`n"|ConvertFrom-Json
        Assert ($consumerReport.passed -and $consumerReport.scope -eq 'Consumer') "$layout Consumer receipt invalid"
        $cli=@(& pwsh -NoProfile -File (Join-Path $provider 'scripts/agents.ps1') -Root $provider deploy dry-run -TargetPath $target -Layout $layout -Json 2>&1)
        Assert ($LASTEXITCODE -eq 0) "$layout CLI deploy dry-run failed: $($cli -join ' ')"
        $cliPlan=$cli -join "`n"|ConvertFrom-Json
        Assert ($cliPlan.plan_digest -match '^[a-f0-9]{64}$') "$layout CLI plan digest missing"
        $managedPath=Join-Path $target 'AGENTS.md'
        $upgradePlan=Get-DeploymentPlan $mirror $target 'auto'
        $upgrade=Invoke-Deployment $mirror $target 'auto' $upgradePlan.plan_digest
        Assert ($upgrade.status -eq 'committed') "$layout repair deployment did not commit"
        $rolled=Restore-Deployment $target $upgrade.transaction_id
        Assert ($rolled.status -eq 'rolled_back' -and (Get-Content -Raw $managedPath) -eq $originalAgents) "$layout rollback did not restore the original file state"
        Assert (Test-Path -LiteralPath (Join-Path $target 'business.txt')) "$layout rollback removed business data"
        $redploy=Deploy $target $layout
        Assert ($redploy.result.status -eq 'unchanged') "$layout redeploy after rollback was not idempotent"
        $tamperTarget=Join-Path $scratch ($layout+' damaged-backup')
        [IO.Directory]::CreateDirectory($tamperTarget)|Out-Null
        $tamperFirst=Deploy $tamperTarget $layout
        $tamperPath=Join-Path $tamperTarget 'AGENTS.md'
        $tamperPlan=Get-DeploymentPlan $mirror $tamperTarget 'auto'
        $tamperCommit=Invoke-Deployment $mirror $tamperTarget 'auto' $tamperPlan.plan_digest
        $journalPath=Get-DeploymentJournalPath $tamperTarget $tamperCommit.transaction_id
        $journal=Read-AgentJson $journalPath;$originalJournal=$journal|ConvertTo-Json -Depth 40|ConvertFrom-Json -AsHashtable
        $journal.entries[0].backup='AAAA'
        Write-AgentJson $journalPath $journal -Root $tamperTarget
        Reject { Restore-Deployment $tamperTarget $tamperCommit.transaction_id } "$layout accepted a damaged rollback backup"
        Write-AgentJson $journalPath $originalJournal -Root $tamperTarget
        $null=Restore-Deployment $tamperTarget $tamperCommit.transaction_id
        Assert ((Get-Content -Raw $tamperPath) -eq $originalAgents) "$layout rollback after backup repair restored the wrong bytes"
    }
    $success=$true;"PASS: $script:assertions v5 deployment assertions"
} finally { $null=Complete-AgentRun $provider $run.id $(if($success){'completed'}else{'failed'}) }
