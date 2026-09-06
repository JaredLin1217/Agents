. "$PSScriptRoot/agent-core.ps1"
function Assert-OwnedPath([string]$Path) {
    if($Path -match '\\|(^|/)\.\.?(/|$)|:|//' -or $Path.EndsWith('/')) { throw "Noncanonical owned path: $Path" }
    if ($Path -match '(^|/)memory(/|\.)|^\.codex/|^\.git/|^\.agents/runtime/|(^|/)README\.md$|(^|/)agents\.json$') {
        throw "Protected target data: $Path"
    }
    if ($Path -notmatch '^(AGENTS\.md|\.agents/\.gitignore|\.agents/managed\.json|(?:\.agents/)?(?:scripts|schemas|docs/agents|docs/runbooks|docs/templates)/.+|\.agents/skills/.+)$') {
        throw "Path is outside the managed boundary: $Path"
    }
}
function Get-DeploymentEntries([string]$Provider, [string]$Layout) {
    $catalog=Read-AgentJson (Resolve-SafePath $Provider 'docs/agents/deployment.json') (Resolve-SafePath $Provider 'schemas/deployment.schema.json')
    $seen=@{}
    $sources=@{}
    foreach($file in $catalog.files) {
        $path=[string]$file[$Layout]
        Assert-OwnedPath $path
        if($seen.ContainsKey($path)) { throw "Duplicate destination: $path" }
        $seen[$path]=$true
        $source=Resolve-SafePath $Provider $file.source
        if($sources.ContainsKey($file.source)) { throw "Duplicate source: $($file.source)" }; $sources[$file.source]=$true
        $hash=Get-AgentHash $source
        if($hash -eq 'missing') { throw "Missing deployment source: $($file.source)" }
        [ordered]@{source=$file.source;path=$path;sha256=$hash}
    }
}
function Get-DeploymentPlan([string]$Provider,[string]$Target,[string]$Layout) {
    $manifestPath=Resolve-SafePath $Target '.agents/managed.json'
    $old=@{files=@()}
    if(Test-Path -LiteralPath $manifestPath) {
        $old=Read-AgentJson $manifestPath (Resolve-SafePath $Provider 'schemas/managed.schema.json')
        if($Layout -eq 'auto') { $Layout=$old.layout }
        if($Layout -ne $old.layout) { throw 'Layout migration requires a separately reviewed migration, not an upgrade.' }
    } elseif($Layout -eq 'auto') {
        if(Test-Path -LiteralPath (Join-Path $Target '.agents/docs/agents')) { $Layout='dot-agents-layout' }
        else { $Layout='root-layout' }
    }
    $entries=@(Get-DeploymentEntries $Provider $Layout)
    $owned=@{}
    foreach($file in $old.files) {
        Assert-OwnedPath $file.path
        if($owned.ContainsKey($file.path)) { throw "Duplicate owned path: $($file.path)" }
        $owned[$file.path]=$file
    }
    $ops=[Collections.Generic.List[object]]::new()
    $conflicts=[Collections.Generic.List[string]]::new()
    foreach($entry in $entries) {
        $actual=Get-AgentHash (Resolve-SafePath $Target $entry.path)
        if($owned.ContainsKey($entry.path)) {
            if($actual -ne $owned[$entry.path].sha256) { $conflicts.Add("Modified managed file: $($entry.path)") }
        } elseif($actual -ne 'missing') { $conflicts.Add("Unowned existing file: $($entry.path)") }
        $ops.Add([ordered]@{path=$entry.path;source=$entry.source;before=$actual;after=$entry.sha256;
            action=$(if($actual -eq $entry.sha256){'unchanged'}elseif($actual -eq 'missing'){'create'}else{'update'})})
    }
    foreach($file in $old.files) {
        if($file.path -notin @($entries | ForEach-Object path)) {
            $actual=Get-AgentHash (Resolve-SafePath $Target $file.path)
            if($actual -ne $file.sha256) { $conflicts.Add("Modified retired file: $($file.path)") }
            $ops.Add([ordered]@{path=$file.path;source='';before=$actual;after='missing';action='delete'})
        }
    }
    $version=(Read-AgentJson (Join-Path $Provider 'agents.json')).version
    $manifest=[ordered]@{schema_version='agents-managed/v3';version=$version;layout=$Layout;files=$entries}
    $manifestText=($manifest|ConvertTo-Json -Depth 20).Replace("`r`n","`n")+"`n"
    $manifestHash=Get-TextHash $manifestText
    $ops.Add([ordered]@{path='.agents/managed.json';source='';before=(Get-AgentHash $manifestPath);after=$manifestHash;
        action=$(if((Get-AgentHash $manifestPath) -eq $manifestHash){'unchanged'}else{'update'})})
    $data=[ordered]@{layout=$Layout;operations=@($ops.ToArray());conflicts=@($conflicts.ToArray());manifest=$manifest}
    $digest=Get-TextHash (([IO.Path]::GetFullPath($Target)) + ($data|ConvertTo-Json -Depth 30 -Compress))
    $data['plan_digest']=$digest
    return $data
}
function Restore-Deployment([string]$Target,[string]$Id) {
    $lockPath=Resolve-SafePath $Target '.agents/runtime/deployment.lock'
    [IO.Directory]::CreateDirectory((Split-Path -Parent $lockPath))|Out-Null
    $lock=[IO.File]::Open($lockPath,[IO.FileMode]::OpenOrCreate,[IO.FileAccess]::Write,[IO.FileShare]::None)
    try { return Restore-DeploymentContent $Target $Id }
    finally { $lock.Dispose(); Remove-Item -LiteralPath $lockPath }
}
function Restore-DeploymentContent([string]$Target,[string]$Id) {
    if($Id -notmatch '^deploy-[a-f0-9]{32}$') { throw 'Invalid transaction ID.' }
    $journalPath=Resolve-SafePath $Target ".agents/runtime/deployments/$Id.json"
    $journal=Read-AgentJson $journalPath
    if($journal.id -ne $Id -or $journal.status -notin @('committed','applying') -or -not $journal.entries.Count) { throw 'Transaction is not rollback eligible.' }
    $seen=@{}
    foreach($entry in $journal.entries) {
        Assert-OwnedPath $entry.path
        if($seen.ContainsKey($entry.path) -or $entry.before -notmatch '^(missing|[a-f0-9]{64})$' -or $entry.after -notmatch '^(missing|[a-f0-9]{64})$') { throw 'Invalid rollback journal.' }
        $seen[$entry.path]=$true
        $actual=Get-AgentHash (Resolve-SafePath $Target $entry.path)
        if($actual -notin @($entry.before,$entry.after)) { throw "Rollback conflict: $($entry.path)" }
        if($entry.before -ne 'missing') {
            $bytes=[Convert]::FromBase64String($entry.backup)
            $hash=[Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($bytes)).ToLowerInvariant()
            if($hash -ne $entry.before) { throw "Damaged rollback backup: $($entry.path)" }
        }
    }
    foreach($entry in @($journal.entries)[($journal.entries.Count-1)..0]) {
        $dest=Resolve-SafePath $Target $entry.path
        if((Get-AgentHash $dest) -notin @($entry.before,$entry.after)) { throw "Concurrent rollback conflict: $($entry.path)" }
        if($entry.before -eq 'missing') { if(Test-Path -LiteralPath $dest) { Remove-Item -LiteralPath $dest } }
        else { [IO.Directory]::CreateDirectory((Split-Path -Parent $dest))|Out-Null; [IO.File]::WriteAllBytes($dest,[Convert]::FromBase64String($entry.backup)) }
    }
    $journal.status='rolled_back'
    Write-AgentJson $journalPath $journal
    return @{transaction_id=$Id;status='rolled_back'}
}
function Invoke-Deployment([string]$Provider,[string]$Target,[string]$Layout,[string]$ExpectedPlanDigest,[switch]$DryRun) {
    if(-not(Test-Path -LiteralPath $Target -PathType Container)) { throw 'Target must already exist.' }
    $Target=[IO.Path]::GetFullPath($Target)
    if($Target -eq [IO.Path]::GetFullPath($Provider)) { throw 'Provider cannot deploy into itself.' }
    $plan=Get-DeploymentPlan $Provider $Target $Layout
    if($DryRun) { return $plan }
    if($plan.conflicts.Count) { throw ($plan.conflicts -join '; ') }
    if(-not $ExpectedPlanDigest -or $ExpectedPlanDigest -ne $plan.plan_digest) { throw 'Dry-run approval digest missing or stale.' }
    $changed=@($plan.operations|Where-Object action -NE 'unchanged')
    $runtime=Resolve-SafePath $Target '.agents/runtime/deployments'
    [IO.Directory]::CreateDirectory($runtime)|Out-Null
    $lockPath=Resolve-SafePath $Target '.agents/runtime/deployment.lock'
    $lock=[IO.File]::Open($lockPath,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
    $id='deploy-'+[guid]::NewGuid().ToString('N')
    $journalPath=Resolve-SafePath $Target ".agents/runtime/deployments/$id.json"
    try {
        # Re-read after exclusive acquisition; a preview is not authorization for changed inputs.
        $fresh=Get-DeploymentPlan $Provider $Target $Layout
        if($fresh.plan_digest -ne $ExpectedPlanDigest) { throw 'Deployment inputs changed after preview.' }
        foreach($file in Get-ChildItem -LiteralPath $runtime -Filter '*.json' -File) {
            if((Read-AgentJson $file.FullName).status -eq 'applying') { throw "Interrupted deployment requires rollback: $($file.BaseName)" }
        }
        if(-not $changed.Count) { return @{status='unchanged';plan_digest=$plan.plan_digest} }
        $entries=@($changed|ForEach-Object {
            $dest=Resolve-SafePath $Target $_.path
            @{path=$_.path;before=$_.before;after=$_.after;backup=$(if($_.before -eq 'missing'){''}else{[Convert]::ToBase64String([IO.File]::ReadAllBytes($dest))})}
        })
        $journal=@{id=$id;status='applying';entries=$entries}
        Write-AgentJson $journalPath $journal
        foreach($op in $changed) {
            $dest=Resolve-SafePath $Target $op.path
            if((Get-AgentHash $dest) -ne $op.before) { throw "Concurrent target change: $($op.path)" }
            if($op.action -eq 'delete') { Remove-Item -LiteralPath $dest }
            elseif($op.path -eq '.agents/managed.json') { Write-AgentJson $dest $plan.manifest }
            else {
                $source=Resolve-SafePath $Provider $op.source
                if((Get-AgentHash $source) -ne $op.after) { throw "Concurrent source change: $($op.source)" }
                [IO.Directory]::CreateDirectory((Split-Path -Parent $dest))|Out-Null
                [IO.File]::Copy($source,$dest,$true)
            }
            if((Get-AgentHash $dest) -ne $op.after) { throw "Post-write hash mismatch: $($op.path)" }
        }
        $journal.status='committed'
        Write-AgentJson $journalPath $journal
        return @{status='committed';transaction_id=$id;plan_digest=$plan.plan_digest;changed_paths=@($changed|ForEach-Object path)}
    } finally { $lock.Dispose(); Remove-Item -LiteralPath $lockPath }
}
