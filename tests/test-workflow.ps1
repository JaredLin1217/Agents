#requires -Version 7.4
param()
. "$PSScriptRoot/../scripts/agent-checks.ps1"
. "$PSScriptRoot/../scripts/agent-tasks.ps1"
. "$PSScriptRoot/../scripts/agent-deployment.ps1"
$provider=Get-AgentRoot;$assertions=0;$success=$false;$failure='';$run=New-AgentRun $provider 'Agents v5 core workflow tests' 'test-workflow'
$artifact=Register-AgentArtifact $provider $run.id "$($run.path)/fixtures" 'scratch' 'Disposable v5 core fixtures'
$root=Resolve-SafePath $provider $artifact.path
function Assert($Condition,[string]$Message){if(-not $Condition){throw $Message};$script:assertions++}
function Reject([scriptblock]$Action,[string]$Message){$rejected=$false;try{$null=&$Action}catch{$rejected=$true};Assert $rejected $Message}
function Put([string]$Relative,[string]$Text){$p=Resolve-SafePath $provider "$($artifact.path)/$Relative";[IO.Directory]::CreateDirectory((Split-Path -Parent $p))|Out-Null;[IO.File]::WriteAllText($p,$Text,[Text.UTF8Encoding]::new($false))}
try {
    $project=Read-AgentJson (Join-Path $provider 'agents.json') (Join-Path $provider 'schemas/project.schema.json')
    Assert ($project.version -eq '5.0.0' -and $project.schema_version -eq 'agents-project/v5') 'v5 project contract missing'
    Assert ((Get-Content -Raw AGENTS.md).Length -lt 32768) 'Active rules exceed native default guidance budget'
    Reject { Resolve-SafePath $provider '../outside' } 'Traversal accepted'
    Reject { Resolve-SafePath $provider 'C:/outside' } 'Absolute path accepted'
    Assert ((Test-AgentSyntax $provider @('scripts/agents.ps1','scripts/migrate-v4-to-v5.ps1','scripts/package-plugin.ps1')) -eq $null) 'v5 CLI syntax failed'
    $null=Test-AgentSchemas $provider @('agents.json','docs/agents/sources.json','plugins/agents-governance/plugin.json')
    $knowledge=Get-ProjectKnowledge $provider -Query @('runtime')
    Assert ($knowledge.entries.Count -ge 1 -and $knowledge.gaps.Count -eq 0) 'v5 knowledge recall failed'
    Assert ((Get-ProjectKnowledge $provider -Expand).entries[0].sources.Count -gt 0) 'Knowledge expansion missing provenance'
    $inventory=Get-RuntimeInventory $provider
    Assert ($inventory.unknown.Count -eq 0 -and $inventory.issues.Count -eq 0) 'Primary runtime inventory has unknown content'
    Put 'nested/中文 file.txt' 'portable runtime fixture'
    $footprint=Get-RuntimeFootprint $provider $artifact.path
    Assert ($footprint.items.path -contains "$($artifact.path)/nested/中文 file.txt") 'Unicode runtime path not recorded'
    $taskId='v5-core-'+[guid]::NewGuid().ToString('N')
    $taskInput=@{id=$taskId;objective='Verify v5 core workflow';latest_adjustment='Keep the current authorized requirements';acceptance_criteria=@('Current v5 contract is observable');boundaries=@('AGENTS.md');completed=@('Core contract inspected');open_issues=@();next_steps=@();knowledge_ids=@('M005-semantic-intent-v5');validation_receipts=@();external_actions=@()}
    $saved=Save-AgentTask $provider $taskInput 0
    Assert ($saved.checkpoint.schema_version -eq 'agents-task/v5' -and $saved.checkpoint.revision -eq 1) 'v5 task save failed'
    Reject { Save-AgentTask $provider $taskInput 0 } 'Task CAS accepted stale revision'
    $resumed=Resume-AgentTask $provider $taskId
    Assert (-not $resumed.requires_reinspection) 'Fresh v5 task requires reinspection'
    $taskInput.objective='Complete the verified v5 core workflow';$taskInput.latest_adjustment='Acceptance remains current';$taskInput.completed+=@('CAS and resume verified')
    $completed=Save-AgentTask $provider $taskInput 1 -Complete
    Assert ($completed.checkpoint.status -eq 'completed' -and $completed.checkpoint.requirements.Count -eq 2) 'Task completion/history failed'
    $doctor=(& pwsh -NoProfile -File (Join-Path $provider 'scripts/agents.ps1') doctor -Json)|ConvertFrom-Json -AsHashtable
    Assert ($doctor.status -eq 'ready' -and $doctor.telemetry -eq 'disabled') 'Unified CLI doctor failed'
    $plan=(& pwsh -NoProfile -File (Join-Path $provider 'scripts/agents.ps1') plan -Json)|ConvertFrom-Json -AsHashtable
    Assert ($plan.schema_version -eq 'agents-plan/v5' -and $plan.status -eq 'planned') 'Unified CLI plan failed'
    $success=$true;"PASS: $script:assertions v5 core assertions"
} catch {$failure=$_.Exception.ToString();throw}
finally {if(-not $success){$failure=$failure};$null=Complete-AgentRun $provider $run.id $(if($success){'completed'}else{'failed'})}
