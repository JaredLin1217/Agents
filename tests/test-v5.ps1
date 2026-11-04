#requires -Version 7.4
param()
. "$PSScriptRoot/../scripts/agent-runtime.ps1"
$provider=Get-AgentRoot;$assertions=0;$success=$false;$failure='';$run=New-AgentRun $provider 'Agents v5 packaging and migration tests' 'test-v5'
$artifact=Register-AgentArtifact $provider $run.id "$($run.path)/fixtures" 'scratch' 'Disposable v5 packaging fixtures'
$scratch=Resolve-SafePath $provider $artifact.path
function Assert($Condition,[string]$Message){if(-not $Condition){throw $Message};$script:assertions++}
function Put([string]$Root,[string]$Path,[string]$Text){$p=Resolve-SafePath $Root $Path;[IO.Directory]::CreateDirectory((Split-Path -Parent $p))|Out-Null;[IO.File]::WriteAllText($p,$Text,[Text.UTF8Encoding]::new($false))}
try {
    $manifest=Read-AgentJson (Join-Path $provider 'plugins/agents-governance/plugin.json') (Join-Path $provider 'schemas/plugin.schema.json')
    Assert ($manifest.version -eq '5.0.0' -and $manifest.extensions.'com.openai'.requires_local_executor) 'Portable plugin manifest invalid'
    Assert (-not(Test-Path -LiteralPath (Resolve-SafePath $provider 'plugins/agents-governance/hooks'))) 'Public plugin contains lifecycle hooks'
    $privacy=Get-Content -Raw (Resolve-SafePath $provider 'plugins/agents-governance/README.md')
    Assert ($privacy -match '(?i)telemetry' -and $privacy -match '(?i)secret') 'Plugin privacy boundary not documented'
    $package=(& pwsh -NoProfile -File (Resolve-SafePath $provider 'scripts/package-plugin.ps1'))|ConvertFrom-Json -AsHashtable
    Assert ($package.schema_version -eq 'agents-plugin-package/v5' -and $package.sha256 -match '^[a-f0-9]{64}$') 'Deterministic plugin package failed'
    Assert (Test-Path -LiteralPath (Resolve-SafePath $provider $package.path)) 'Plugin package missing from runtime'
    $extracted=Join-Path $scratch 'extracted-plugin';[IO.Directory]::CreateDirectory($extracted)|Out-Null
    [IO.Compression.ZipFile]::ExtractToDirectory((Resolve-SafePath $provider $package.path),$extracted)
    Assert (Test-Path -LiteralPath (Join-Path $extracted 'migrations/v4/schemas/managed.schema.json')) 'Plugin package omitted the v4 migration schema'
    $target=Join-Path $scratch 'v4-consumer';[IO.Directory]::CreateDirectory($target)|Out-Null
    Put $target 'AGENTS.md' 'v4 managed rules'
    Put $target 'business.txt' 'business data must survive migration'
    $managedPath=Resolve-SafePath $target '.agents/managed.json';[IO.Directory]::CreateDirectory((Split-Path -Parent $managedPath))|Out-Null
    $old=@{schema_version='agents-managed/v3';version='4.0.0';layout='root-layout';files=@(@{source='AGENTS.md';path='AGENTS.md';sha256=(Get-AgentHash (Join-Path $target 'AGENTS.md'))})}
    [IO.File]::WriteAllText($managedPath,($old|ConvertTo-Json -Depth 20)+"`n",[Text.UTF8Encoding]::new($false))
    $plan=(& pwsh -NoProfile -File (Resolve-SafePath $provider 'scripts/migrate-v4-to-v5.ps1') -Root $target -Action Plan)|ConvertFrom-Json -AsHashtable
    Assert ($plan.schema_version -eq 'agents-migration-plan/v5' -and $plan.to_version -eq '5.0.0') 'v4 migration plan invalid'
    $result=(& pwsh -NoProfile -File (Resolve-SafePath $provider 'scripts/migrate-v4-to-v5.ps1') -Root $target -Action Apply -ExpectedDigest $plan.digest -Reason 'Reviewed v5 migration fixture')|ConvertFrom-Json -AsHashtable
    $new=Read-AgentJson $managedPath (Resolve-SafePath $provider 'schemas/managed.schema.json')
    Assert ($result.status -eq 'migrated' -and $new.schema_version -eq 'agents-managed/v5') 'v4 migration did not produce v5 manifest'
    Assert ((Get-Content -Raw (Join-Path $target 'business.txt')) -eq 'business data must survive migration') 'Migration touched business data'
    $pluginTarget=Join-Path $scratch 'plugin-v4-consumer';[IO.Directory]::CreateDirectory($pluginTarget)|Out-Null
    Put $pluginTarget 'AGENTS.md' 'plugin v4 managed rules'
    Put $pluginTarget 'business.txt' 'plugin business data must survive migration'
    $pluginManaged=Resolve-SafePath $pluginTarget '.agents/managed.json';[IO.Directory]::CreateDirectory((Split-Path -Parent $pluginManaged))|Out-Null
    $pluginOld=@{schema_version='agents-managed/v3';version='4.0.0';layout='root-layout';files=@(@{source='AGENTS.md';path='AGENTS.md';sha256=(Get-AgentHash (Join-Path $pluginTarget 'AGENTS.md'))})}
    [IO.File]::WriteAllText($pluginManaged,($pluginOld|ConvertTo-Json -Depth 20)+"`n",[Text.UTF8Encoding]::new($false))
    $pluginMigration=Join-Path $extracted 'scripts/migrate-v4-to-v5.ps1'
    $pluginPlan=(& pwsh -NoProfile -File $pluginMigration -Root $pluginTarget -Action Plan)|ConvertFrom-Json -AsHashtable
    Assert ($pluginPlan.schema_version -eq 'agents-migration-plan/v5') 'Extracted plugin migration plan failed'
    $pluginResult=(& pwsh -NoProfile -File $pluginMigration -Root $pluginTarget -Action Apply -ExpectedDigest $pluginPlan.digest -Reason 'Reviewed extracted plugin migration fixture')|ConvertFrom-Json -AsHashtable
    $pluginNew=Read-AgentJson $pluginManaged (Resolve-SafePath $provider 'schemas/managed.schema.json')
    Assert ($pluginResult.status -eq 'migrated' -and $pluginNew.schema_version -eq 'agents-managed/v5') 'Extracted plugin migration did not produce v5 manifest'
    Assert ((Get-Content -Raw (Join-Path $pluginTarget 'business.txt')) -eq 'plugin business data must survive migration') 'Extracted plugin migration touched business data'
    $inventory=Get-RuntimeInventory $provider
    Assert ($inventory.unknown.Count -eq 0 -and $inventory.issues.Count -eq 0) 'Packaging/migration left unknown runtime content'
    $success=$true;"PASS: $script:assertions v5 packaging assertions"
} catch {$failure=$_.Exception.ToString();throw}
finally {$null=Complete-AgentRun $provider $run.id $(if($success){'completed'}else{'failed'})}
