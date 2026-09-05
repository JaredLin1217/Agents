#requires -Version 7.0
param([Parameter(Mandatory)][string]$TargetPath,
      [ValidateSet('auto','root-layout','dot-agents-layout')][string]$LayoutProfile='auto',
      [switch]$DryRun,[string]$ExpectedPlanDigest,[string]$Rollback)
. "$PSScriptRoot/agent-deployment.ps1"
$provider=Get-AgentRoot
$target=[IO.Path]::GetFullPath($TargetPath)
if($Rollback) { Restore-Deployment $target $Rollback|ConvertTo-Json -Depth 30 }
else { Invoke-Deployment $provider $target $LayoutProfile $ExpectedPlanDigest -DryRun:$DryRun|ConvertTo-Json -Depth 30 }
