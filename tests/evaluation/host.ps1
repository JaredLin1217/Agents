. "$PSScriptRoot/../../scripts/agent-core.ps1"
function Get-EvaluationPermissionArguments {
    # Explicit roots avoid inheriting writable system temp directories.
    # Pass the whole TOML value: dotted CLI keys do not preserve quoted path keys.
    return @('-c','default_permissions="agents-evaluation"','-c',
        'permissions={agents-evaluation={filesystem={":minimal"="read",":workspace_roots"={"."="write",".agents"="write",".git"="write",".codex"="read"}},network={enabled=false}}}')
}
function Assert-EvaluationLaunchPath([string]$Path) {
    $allowed=[IO.Path]::GetFullPath((Join-Path ([IO.Path]::GetTempPath()) 'codex-agent-status/jared-ai-team-v3-evaluation'))
    $full=[IO.Path]::GetFullPath($Path)
    if(-not $full.StartsWith($allowed+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)) {
        throw 'Model evaluation writes are authorized only inside disposable evaluation scratch.'
    }
    $cursor=Get-Item -Force -LiteralPath $full -ErrorAction Stop
    while($cursor) {
        if($cursor.Attributes -band [IO.FileAttributes]::ReparsePoint) { throw 'Linked evaluation roots are not allowed.' }
        $cursor=$cursor.Parent
    }
}
function Get-EvaluationHostArguments([string]$Root,[string]$LogPrefix,[string]$Target='') {
    $arguments=@('exec','--strict-config','--ignore-user-config','--ephemeral','--json','--color','never',
        '-C',$Root,'-m','gpt-6-astra','-c','model_reasoning_effort="xhigh"',
        '-c','memories.use_memories=false','-c','memories.generate_memories=false','-c','web_search="disabled"',
        '-c','features.multi_agent=false','-c','approval_policy="never"')
    $arguments+=Get-EvaluationPermissionArguments
    # Ignoring user config must not silently omit the provisioned Windows backend.
    if($IsWindows) { $arguments+=@('-c','windows.sandbox="elevated"') }
    if($Target) { $arguments+=@('--add-dir',$Target) }
    return $arguments+@('-o',"$LogPrefix.answer.txt",'-')
}
function New-EvaluationProcessInfo([string]$CodexPath,[string]$Root) {
    Assert-EvaluationLaunchPath $Root
    $temp=Resolve-SafePath $Root '.agents/runtime/temp'
    [IO.Directory]::CreateDirectory($temp)|Out-Null
    $psi=[Diagnostics.ProcessStartInfo]::new($CodexPath)
    $psi.WorkingDirectory=$Root; $psi.UseShellExecute=$false; $psi.CreateNoWindow=$true
    $psi.RedirectStandardOutput=$true; $psi.RedirectStandardError=$true; $psi.RedirectStandardInput=$true
    foreach($name in @('TEMP','TMP','TMPDIR')) { $psi.Environment[$name]=$temp }
    return $psi
}
function Convert-EvaluationEvents([string]$Output,[string]$ErrorOutput) {
    $events=@(); $parseErrors=0
    foreach($line in ($Output -split "`n"|Where-Object {$_})) {
        try{$events+=ConvertFrom-Json -InputObject $line -AsHashtable -ErrorAction Stop}catch{$parseErrors++}
    }
    $usages=@($events|Where-Object { $_.type -eq 'turn.completed' -and $_.Contains('usage') }|ForEach-Object usage)
    $calls=@($events|Where-Object { $_.type -eq 'item.completed' -and $_.item.type -in @('command_execution','mcp_tool_call','web_search','tool_call','collab_tool_call','file_change') }|ForEach-Object item)
    $usage=$null
    if($usages.Count) {
        $usage=@{}; foreach($key in @('input_tokens','cached_input_tokens','cache_write_input_tokens','output_tokens','reasoning_output_tokens')) {
            $values=@($usages|Where-Object { $_.Contains($key) }|ForEach-Object {$_[$key]})
            $usage[$key]=if($values.Count -eq $usages.Count){($values|Measure-Object -Sum).Sum}else{$null}
        }
    }
    $denied=$ErrorOutput -match '(?i)blocked by policy|access is denied|permission denied|Access to the path .+ is denied'
    foreach($call in $calls) {
        if($call.Contains('aggregated_output') -and $call.aggregated_output -match '(?i)blocked by policy|access is denied|permission denied|Access to the path .+ is denied') { $denied=$true }
    }
    return @{usage=$usage;tool_calls=@($calls|Group-Object id).Count;parse_errors=$parseErrors;calls=$calls;
        environment_blocked=[bool]$denied;turn_completed=($usages.Count -gt 0);
        error_events=@($events|Where-Object type -In @('error','turn.failed'))}
}
function Invoke-EvaluationHost {
    param([string]$CodexPath,[string]$Root,[string]$Prompt,[string]$LogPrefix,[int]$TimeoutSeconds=600,[string]$Target='')
    Assert-EvaluationLaunchPath $Root
    Assert-EvaluationLaunchPath (Split-Path -Parent $LogPrefix)
    if($Target) { Assert-EvaluationLaunchPath $Target }
    $psi=New-EvaluationProcessInfo $CodexPath $Root
    foreach($arg in Get-EvaluationHostArguments $Root $LogPrefix $Target) { $psi.ArgumentList.Add($arg) }
    $process=[Diagnostics.Process]::new(); $process.StartInfo=$psi
    try {
        $timer=[Diagnostics.Stopwatch]::StartNew(); $null=$process.Start()
        $stdout=$process.StandardOutput.ReadToEndAsync(); $stderr=$process.StandardError.ReadToEndAsync()
        $process.StandardInput.Write($Prompt); $process.StandardInput.Close()
        $timedOut=-not $process.WaitForExit($TimeoutSeconds*1000)
        if($timedOut) { $process.Kill($true); $process.WaitForExit() }
        $timer.Stop(); $out=$stdout.GetAwaiter().GetResult(); $err=$stderr.GetAwaiter().GetResult()
        [IO.File]::WriteAllText("$LogPrefix.events.jsonl",$out)
        [IO.File]::WriteAllText("$LogPrefix.stderr.txt",$err)
        $result=Convert-EvaluationEvents $out $err
        $result.exit_code=$process.ExitCode; $result.timed_out=$timedOut; $result.duration_ms=$timer.ElapsedMilliseconds
        $result.answer=if(Test-Path -LiteralPath "$LogPrefix.answer.txt"){Get-Content -Raw -LiteralPath "$LogPrefix.answer.txt"}else{''}
        return $result
    } finally { $process.Dispose() }
}
function Test-EvaluationFilesystem([string]$CodexPath,[string]$Root,[string]$Scratch) {
    Assert-EvaluationLaunchPath $Root
    $settings=Join-Path $Root '.codex/sentinel.txt'
    [IO.Directory]::CreateDirectory((Split-Path -Parent $settings))|Out-Null
    [IO.File]::WriteAllText($settings,'read-only sentinel')
    $outside=Join-Path $Scratch 'outside-write-probe.txt'
    $code=@'
$ErrorActionPreference='Stop'
$result=@{}
[IO.File]::WriteAllText((Join-Path (Get-Location) '.agents/runtime/boundary.txt'),'allowed')
$result.runtime_write=$true
$settings=Join-Path (Get-Location) '.codex/sentinel.txt'
$result.settings_read=([IO.File]::ReadAllText($settings) -eq 'read-only sentinel')
foreach($entry in @{settings_write='SETTINGS_PATH';outside_write='OUTSIDE_PATH'}.GetEnumerator()) {
    try { [IO.File]::WriteAllText($entry.Value,'not allowed'); $result[$entry.Key]=$true }
    catch [UnauthorizedAccessException] { $result[$entry.Key]=$false }
}
$result|ConvertTo-Json -Compress
'@
    $code=$code.Replace('SETTINGS_PATH',$settings.Replace("'","''")).Replace('OUTSIDE_PATH',$outside.Replace("'","''"))
    $args=@('sandbox','-P','agents-evaluation','--include-managed-config','-C',$Root)+(Get-EvaluationPermissionArguments)
    if($IsWindows) { $args+=@('-c','windows.sandbox="elevated"') }
    $args+=@('--',(Get-Command pwsh -ErrorAction Stop).Source,'-NoProfile','-NonInteractive','-EncodedCommand',[Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($code)))
    $psi=New-EvaluationProcessInfo $CodexPath $Root
    foreach($arg in $args) { $psi.ArgumentList.Add($arg) }
    $process=[Diagnostics.Process]::new(); $process.StartInfo=$psi
    try {
        $null=$process.Start(); $process.StandardInput.Close()
        $stdout=$process.StandardOutput.ReadToEndAsync(); $stderr=$process.StandardError.ReadToEndAsync()
        if(-not $process.WaitForExit(30000)) { $process.Kill($true); $process.WaitForExit() }
        $output=$stdout.GetAwaiter().GetResult(); $errors=$stderr.GetAwaiter().GetResult(); $exitCode=$process.ExitCode
    } finally { $process.Dispose() }
    [IO.File]::WriteAllText((Join-Path $Scratch 'filesystem-preflight.log'),($output+"`n"+$errors))
    $result=$null
    try { $result=ConvertFrom-Json -AsHashtable -InputObject $output -ErrorAction Stop } catch {}
    $passed=$exitCode -eq 0 -and $null -ne $result -and $result.runtime_write -and $result.settings_read -and
        $result.settings_write -ceq $false -and $result.outside_write -ceq $false -and
        [IO.File]::ReadAllText($settings) -eq 'read-only sentinel' -and -not(Test-Path -LiteralPath $outside)
    return @{passed=[bool]$passed;exit_code=$exitCode;observations=$result;
        claims=@('Expected-denial filesystem probes only.','Network is configured disabled; no network enforcement claim from this probe.')}
}
function Test-EvaluationHost([string]$CodexPath,[string]$Scratch,[int]$TimeoutSeconds=180) {
    $root=Resolve-SafePath $Scratch 'host-preflight'
    if(Test-Path -LiteralPath $root) { throw 'Preflight requires a fresh fixture.' }
    [IO.Directory]::CreateDirectory((Join-Path $root '.agents/runtime'))|Out-Null
    [IO.File]::WriteAllText((Join-Path $root 'input.txt'),'fixture value 37')
    [IO.File]::WriteAllText((Join-Path $root '.gitignore'),".agents/runtime/`n")
    $filesystem=Test-EvaluationFilesystem $CodexPath $root $Scratch
    if(-not $filesystem.passed) { return @{passed=$false;filesystem=$filesystem;model_started=$false} }
    $null=Invoke-AgentGit $root @('init','-q')
    $null=Invoke-AgentGit $root @('config','user.name','Evaluation')
    $null=Invoke-AgentGit $root @('config','user.email','eval@example.invalid')
    $null=Invoke-AgentGit $root @('add','.')
    $null=Invoke-AgentGit $root @('commit','-qm','host preflight fixture')
    $head=[string](Invoke-AgentGit $root @('rev-parse','HEAD'))
    $prompt='Perform only this disposable environment preflight, in order: (1) read input.txt; (2) create output.txt with exactly the same bytes; (3) write .agents/runtime/probe.json containing {"value":37}; (4) use Git to create one local commit containing only output.txt. Do not hand-edit Git metadata. Only this workspace is authorized. No network, external reads, global settings, permission changes or other writes. If any action is denied, stop immediately and report it. Do not retry or use an alternative mechanism. Do not claim success without completing the actions.'
    $execution=Invoke-EvaluationHost -CodexPath $CodexPath -Root $root -Prompt $prompt -LogPrefix (Join-Path $Scratch 'host-preflight') -TimeoutSeconds $TimeoutSeconds
    $copy=(Get-AgentHash (Join-Path $root 'input.txt')) -eq (Get-AgentHash (Join-Path $root 'output.txt'))
    $state=$false
    try { $state=(Read-AgentJson (Join-Path $root '.agents/runtime/probe.json')).value -eq 37 } catch {}
    $committed=$head -ne [string](Invoke-AgentGit $root @('rev-parse','HEAD'))
    $paths=@(Invoke-AgentGit $root @('show','--pretty=format:','--name-only','HEAD')|Where-Object {$_})
    $committed=$committed -and $paths.Count -eq 1 -and $paths[0] -eq 'output.txt'
    return @{passed=($copy -and $state -and $committed -and $execution.exit_code -eq 0 -and -not $execution.timed_out -and
        -not $execution.environment_blocked -and $execution.turn_completed -and $execution.parse_errors -eq 0 -and $execution.error_events.Count -eq 0);
        filesystem=$filesystem;model_started=$true;read_write_passed=$copy;runtime_write_passed=$state;local_commit_passed=$committed;
        environment_blocked=$execution.environment_blocked;duration_ms=$execution.duration_ms;usage=$execution.usage;
        tool_calls=$(if($execution.environment_blocked){$null}else{$execution.tool_calls});completed_tool_items=$execution.tool_calls;
        exit_code=$execution.exit_code;timed_out=$execution.timed_out;event_parse_errors=$execution.parse_errors;
        permission_profile='agents-evaluation';command_network_enabled=$false;codex_settings_access='read';
        windows_backend=$(if($IsWindows){'elevated'}else{'not-applicable'});
        claims=@('Environment preflight only; not a task sample.','No policy bypass or global permission changes.')}
}
