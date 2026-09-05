#requires -Version 7.0
param([ValidateSet('Recall','Promote','Index')][string]$Action='Recall', [string]$Query='', [string]$InputPath, [string]$Root)
. "$PSScriptRoot/agent-core.ps1"
if (-not $Root) { $Root=Get-AgentRoot }
$settings=Get-ProjectSettings $Root
$directory=Resolve-SafePath $Root $settings.knowledge_directory
$schema=Get-AgentAsset $Root 'schemas/knowledge.schema.json'
function Test-KnowledgeSources($entry) {
    if([DateTimeOffset]::Parse($entry.verified_utc) -gt [DateTimeOffset]::UtcNow.AddMinutes(1)) { return $false }
    foreach($source in $entry.sources) {
        if ((Get-AgentHash (Resolve-SafePath $Root $source.path)) -ne $source.sha256) { return $false }
    }
    return $true
}
if($Action -eq 'Promote') {
    if(-not $InputPath) { throw 'Promotion requires an explicit reviewed entry.' }
    $entry=Read-AgentJson (Resolve-SafePath $Root $InputPath) $schema
    if($entry.status -ne 'active' -or -not (Test-KnowledgeSources $entry)) { throw 'Only active, source-verified entries may be promoted.' }
    $destination=Resolve-SafePath $Root "$($settings.knowledge_directory)/$($entry.id).json"
    if(Test-Path -LiteralPath $destination) { throw 'Existing knowledge is immutable; create a new ID with supersedes.' }
    foreach($id in $entry.supersedes) {
        if($id -eq $entry.id -or -not (Test-Path -LiteralPath (Resolve-SafePath $Root "$($settings.knowledge_directory)/$id.json"))) {
            throw "Unknown/self supersession: $id"
        }
    }
    Write-AgentJson $destination $entry
}
$entries=[Collections.Generic.List[object]]::new()
$gaps=[Collections.Generic.List[string]]::new()
if(Test-Path -LiteralPath $directory) {
    foreach($file in Get-ChildItem -LiteralPath $directory -Filter '*.json' -File) {
        try {
            $entry=Read-AgentJson $file.FullName $schema
            $entry['path']=[IO.Path]::GetRelativePath($Root,$file.FullName).Replace('\','/')
            $entry['fresh']=Test-KnowledgeSources $entry
            $entries.Add($entry)
        } catch { $gaps.Add("Invalid knowledge: $($file.Name)") }
    }
}
$superseded=@($entries | Where-Object { $_.fresh -and $_.status -eq 'active' } | ForEach-Object { $_.supersedes })
foreach($entry in $entries) {
    if(-not $entry.fresh -and $entry.status -ne 'superseded' -and $entry.id -notin $superseded) { $gaps.Add("Source changed: $($entry.id)") }
    if($entry.id -in $entry.supersedes) { $gaps.Add("Self-supersession: $($entry.id)"); $entry.status='conflicted' }
}
$active=@($entries | Where-Object { $_.fresh -and $_.status -eq 'active' -and $_.id -notin $superseded })
$duplicates=@($entries | Group-Object id | Where-Object Count -GT 1 | ForEach-Object Name)
$active=@($active | Where-Object { $_.id -notin $duplicates })
foreach($id in $duplicates) { $gaps.Add("Duplicate ID suppressed: $id") }
# Explicit same-scope conflicts are suspended, not resolved by timestamp.
$conflicts=@($entries | Where-Object status -EQ 'conflicted' | ForEach-Object scope)
$active=@($active | Where-Object { $_.scope -notin $conflicts })
foreach($scope in $conflicts) { $gaps.Add("Conflicted scope suppressed: $scope") }
$index=@($active | Sort-Object id | ForEach-Object { @{id=$_.id;type=$_.type;conclusion=$_.conclusion;scope=$_.scope;path=$_.path} })
if($Action -in @('Index','Promote')) {
    $indexPath=Resolve-SafePath $Root "$($settings.runtime_directory)/memory-index.json"
    Write-AgentJson $indexPath @{schema_version='agents-memory-index/v3';entries=$index;gaps=@($gaps.ToArray())}
}
$selected=if($Query) { @($index | Where-Object { ($_.conclusion+' '+$_.scope).IndexOf($Query,[StringComparison]::OrdinalIgnoreCase) -ge 0 }) } else { $index }
@{entries=@($selected);gaps=@($gaps.ToArray());source='verified entry files; cached index not trusted'}|ConvertTo-Json -Depth 12
