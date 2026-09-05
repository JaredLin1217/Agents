. "$PSScriptRoot/../../scripts/agent-core.ps1"
function Get-EvaluationSnapshot([string]$Root) {
    if((Get-Item -Force -LiteralPath $Root).Attributes -band [IO.FileAttributes]::ReparsePoint) { throw 'Linked evaluation root.' }
    $snapshot=@{}
    $pending=[Collections.Generic.Stack[string]]::new(); $pending.Push('')
    while($pending.Count) {
        $relative=$pending.Pop()
        $directory=if($relative){Resolve-SafePath $Root $relative}else{$Root}
        foreach($item in Get-ChildItem -LiteralPath $directory -Force) {
            if($item.Name -eq '.git') { continue }
            $path=($relative+'/'+$item.Name).TrimStart('/')
            if($path -in @('.agents/runtime','workload/target/.agents/runtime')) { continue }
            if($item.Attributes -band [IO.FileAttributes]::ReparsePoint) { throw "Linked evaluation path: $path" }
            if($item.PSIsContainer) { $pending.Push($path) }
            else { $snapshot[$path]=Get-AgentHash $item.FullName }
        }
    }
    return $snapshot
}
function Compare-EvaluationSnapshot($Before,$After) {
    foreach($path in @(@($Before.Keys)+@($After.Keys)|Sort-Object -Unique)) {
        $old=if($Before.ContainsKey($path)){$Before[$path]}else{'missing'}
        $new=if($After.ContainsKey($path)){$After[$path]}else{'missing'}
        if($old -ne $new) { $path }
    }
}
function Get-EvaluationTaskSnapshot([string]$Root,[string]$Target) {
    $snapshot=Get-EvaluationSnapshot $Root
    foreach($entry in (Get-EvaluationSnapshot $Target).GetEnumerator()) {
        $path='workload/target/'+$entry.Key
        if($snapshot.ContainsKey($path)) { throw "Ambiguous evaluation path: $path" }
        $snapshot[$path]=$entry.Value
    }
    return $snapshot
}
function Remove-EvaluationGradingFiles([string]$Root) {
    # Keep offline regression dependencies; remove only prompts and independent graders.
    foreach($path in @('tests/evaluation/cases.json','tests/evaluation/fixture.ps1','tests/evaluation/run-evaluation.ps1')) {
        $file=Resolve-SafePath $Root $path
        if(Test-Path -LiteralPath $file -PathType Leaf) { Remove-Item -LiteralPath $file }
    }
}
function Test-EvaluationRollbackState([bool]$DeploymentVerified,$Before,$After) {
    return ($DeploymentVerified -and @(Compare-EvaluationSnapshot $Before $After).Count -eq 0)
}
function Test-EvaluationDeployment([string]$Root,[string]$Target) {
    if(-not(Test-Path -LiteralPath (Join-Path $Target 'AGENTS.md')) -or
        (Get-Content -Raw -LiteralPath (Join-Path $Target 'README.md')) -ne 'Target-owned product documentation.') { return $false }
    if(Test-Path -LiteralPath (Join-Path $Root 'agents.json')) {
        . "$PSScriptRoot/../../scripts/agent-deployment.ps1"
        $expected=@(Get-DeploymentEntries $Root 'root-layout')
        $manifest=Read-AgentJson (Join-Path $Target '.agents/managed.json') (Join-Path $Root 'schemas/managed.schema.json')
        if($manifest.layout -ne 'root-layout' -or $manifest.files.Count -ne $expected.Count) { return $false }
        foreach($entry in $expected) {
            $owned=@($manifest.files|Where-Object path -EQ $entry.path)
            if($owned.Count -ne 1 -or $owned[0].sha256 -ne $entry.sha256 -or
                (Get-AgentHash (Resolve-SafePath $Target $entry.path)) -ne $entry.sha256) { return $false }
        }
        return $true
    }
    # The frozen baseline's own preview detects missing or outdated installed assets.
    $out=@(& pwsh -NoProfile -File (Join-Path $Root 'scripts/deploy-agents-workflow.ps1') -TargetPath $Target -Mode full_workflow -LayoutProfile root-layout -DryRun 2>&1)
    return ($LASTEXITCODE -eq 0 -and ($out -join "`n") -match '\[CURRENT\]' -and ($out -join "`n") -notmatch '\[WRITE\]|\[EXISTING\]')
}
