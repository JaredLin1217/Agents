#requires -Version 7.0
param([ValidateSet('root-layout','dot-agents-layout')][string]$Layout='root-layout')
. "$PSScriptRoot/agent-deployment.ps1"
$root=Get-AgentRoot
$run=New-AgentRun $root "Export $Layout package" 'export-release-package'
$artifact=Register-AgentArtifact $root $run.id "$($run.path)/package" 'package' 'Rebuildable deployment package'
$output=Resolve-SafePath $root $artifact.path
try {
    $entries=@(Get-DeploymentEntries $root $Layout)
    foreach($entry in $entries) {
        $destination=Resolve-SafePath $output $entry.path
        [IO.Directory]::CreateDirectory((Split-Path -Parent $destination))|Out-Null
        [IO.File]::Copy((Resolve-SafePath $root $entry.source),$destination)
        if((Get-AgentHash $destination) -ne $entry.sha256) { throw 'Package content changed during export.' }
    }
    Write-AgentJson (Resolve-SafePath $output '.agents/managed.json') ([ordered]@{
        schema_version='agents-managed/v3';version=(Read-AgentJson (Join-Path $root 'agents.json')).version;layout=$Layout;files=$entries
    }) -Root $root
    $null=Complete-AgentRun $root $run.id
    @{path=$artifact.path;layout=$Layout;files=$entries.Count;run_id=$run.id;artifact_id=$artifact.id}|ConvertTo-Json -Compress
} catch { $null=Complete-AgentRun $root $run.id 'failed';throw }
