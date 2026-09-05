#requires -Version 7.0
param([Parameter(Mandatory)][string]$CodexPath,[Parameter(Mandatory)][string]$CandidateCommit,
      [string]$BaselineCommit='5e1643410233858ed70e4567beb01468fe0c2dc8')
. "$PSScriptRoot/environment.ps1"
$provider=Get-AgentRoot
$runId=[guid]::NewGuid().ToString('N')
$scratch=Join-Path ([IO.Path]::GetTempPath()) "codex-agent-status/jared-ai-team-v3-evaluation/$runId"
[IO.Directory]::CreateDirectory($scratch)|Out-Null
$candidate=[string](Invoke-AgentGit $provider @('rev-parse',"$CandidateCommit^{commit}"))
$baseline=[string](Invoke-AgentGit $provider @('rev-parse',"$BaselineCommit^{commit}"))
$report=Test-EvaluationEnvironment $CodexPath $provider $scratch $baseline $candidate
$output=Resolve-SafePath $provider ".agents/runtime/evaluation/environment-$runId.json"
Write-AgentJson $output $report
$report|ConvertTo-Json -Depth 20
"Report: $output"
if(-not $report.passed) { exit 1 }
