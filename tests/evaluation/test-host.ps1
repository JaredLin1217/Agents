#requires -Version 7.0
param([Parameter(Mandatory)][string]$CodexPath)
. "$PSScriptRoot/host.ps1"
$provider=Get-AgentRoot
$id=[guid]::NewGuid().ToString('N')
$scratch=Join-Path ([IO.Path]::GetTempPath()) "codex-agent-status/jared-ai-team-v3-evaluation/$id"
[IO.Directory]::CreateDirectory($scratch)|Out-Null
$report=Test-EvaluationHost $CodexPath $scratch
$report.cli=[string](& $CodexPath --version)
$report.source_commit=[string](Invoke-AgentGit $provider @('rev-parse','HEAD'))
$report.working_tree_clean=@(Invoke-AgentGit $provider @('status','--porcelain')).Count -eq 0
$report.host_script_sha256=Get-AgentHash (Join-Path $PSScriptRoot 'host.ps1')
$report['id']=$id; $report['checked_utc']=[DateTime]::UtcNow.ToString('o')
$path=Resolve-SafePath $provider ".agents/runtime/evaluation/host-$id.json"
Write-AgentJson $path $report
$report|ConvertTo-Json -Depth 10
"Report: $path"
if(-not $report.passed){exit 1}
