#requires -Version 7.0
param([ValidateSet('root-layout','dot-agents-layout')][string]$Layout='root-layout')
. "$PSScriptRoot/agent-deployment.ps1"
$root=Get-AgentRoot
$output=Resolve-SafePath $root ('.agents/runtime/packages/'+[guid]::NewGuid().ToString('N'))
[IO.Directory]::CreateDirectory($output)|Out-Null
$entries=@(Get-DeploymentEntries $root $Layout)
foreach($entry in $entries) {
    $destination=Resolve-SafePath $output $entry.path
    [IO.Directory]::CreateDirectory((Split-Path -Parent $destination))|Out-Null
    [IO.File]::Copy((Resolve-SafePath $root $entry.source),$destination)
    if((Get-AgentHash $destination) -ne $entry.sha256) { throw 'Package content changed during export.' }
}
Write-AgentJson (Resolve-SafePath $output '.agents/managed.json') ([ordered]@{
    schema_version='agents-managed/v3';version=(Read-AgentJson (Join-Path $root 'agents.json')).version;layout=$Layout;files=$entries
})
@{path=[IO.Path]::GetRelativePath($root,$output).Replace('\','/');layout=$Layout;files=$entries.Count}|ConvertTo-Json -Compress
