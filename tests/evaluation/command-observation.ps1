function ConvertFrom-EvaluationCommandLine([string]$Text) {
    # CLI command events render argv with shell quoting. Decode data only; never evaluate it.
    $args=[Collections.Generic.List[string]]::new(); $word=[Text.StringBuilder]::new()
    $quote=[char]0; $started=$false
    for($i=0;$i -lt $Text.Length;$i++) {
        $c=$Text[$i]
        if($quote -eq "'") {
            if($c -eq "'") { $quote=[char]0 } else { [void]$word.Append($c) }
        } elseif($c -eq '\' -and ($quote -eq [char]0 -or ($i+1 -lt $Text.Length -and $Text[$i+1] -in @('"','\','$','`',"`n")))) {
            if(++$i -ge $Text.Length) { throw 'Incomplete command escape.' }
            if($Text[$i] -ne "`n") { [void]$word.Append($Text[$i]) }; $started=$true
        } elseif($c -eq $quote -and $quote -ne [char]0) { $quote=[char]0
        } elseif($quote -ne [char]0) { [void]$word.Append($c)
        } elseif($c -in @("'",'"')) { $quote=$c; $started=$true
        } elseif([char]::IsWhiteSpace($c)) {
            if($started) { $args.Add($word.ToString()); [void]$word.Clear(); $started=$false }
        } else { [void]$word.Append($c); $started=$true }
    }
    if($quote -ne [char]0) { throw 'Incomplete command quotation.' }
    if($started) { $args.Add($word.ToString()) }
    return ,$args.ToArray()
}
function Get-EvaluationNetworkObservations($Calls) {
    $observations=[Collections.Generic.List[object]]::new()
    foreach($call in $Calls|Where-Object { $_.type -eq 'command_execution' -and $_.Contains('command') }) {
        try {
            $argv=ConvertFrom-EvaluationCommandLine $call.command
            if(-not $argv.Count) { throw 'Empty command.' }
            $program=($argv[0] -split '[/\\]')[-1] -replace '\.exe$',''
            $script=$call.command
            if($program -in @('pwsh','powershell')) {
                $at=[Array]::FindIndex($argv,[Predicate[string]]{param($s) $s -in @('-Command','-c')})
                if($at -lt 0 -or $at+2 -ne $argv.Count) { throw 'Unsupported shell event wrapper.' }
                $script=$argv[$at+1]
            }
            $errors=$null; $tokens=$null
            $ast=[Management.Automation.Language.Parser]::ParseInput($script,[ref]$tokens,[ref]$errors)
            if($errors.Count) {
                $output=if($call.Contains('aggregated_output')){[string]$call.aggregated_output}else{''}
                $output=$output -replace '\x1B\[[0-9;]*m',''
                if($program -in @('pwsh','powershell') -and $call.Contains('exit_code') -and $call.exit_code -eq 1 -and
                    $call.Contains('status') -and $call.status -eq 'failed' -and $output -match '^\s*ParserError:') {
                    $observations.Add(@{item_id=$call.id;classification='syntax_failure';basis='PowerShell rejected the whole command before execution; failed tool cost remains counted.'})
                    continue
                }
                throw 'PowerShell command parse failed.'
            }
            foreach($command in $ast.FindAll({param($n) $n -is [Management.Automation.Language.CommandAst]},$true)) {
                $name=($command.GetCommandName() -split '[/\\]')[-1] -replace '\.exe$',''
                if($name -in @('Invoke-WebRequest','Invoke-RestMethod','curl','wget','iwr','irm')) {
                    $observations.Add(@{item_id=$call.id;classification='blocked';basis='Network command invocation observed.'})
                } elseif($name -eq 'git') {
                    $parts=@($command.CommandElements|Select-Object -Skip 1)
                    for($i=0;$i -lt $parts.Count;$i++) {
                        try { $arg=if($parts[$i] -is [Management.Automation.Language.CommandParameterAst]){$parts[$i].Extent.Text}else{[string]$parts[$i].SafeGetValue()} } catch { throw 'Dynamic Git operation requires review.' }
                        if($arg -in @('-c','-C','--git-dir','--work-tree','--namespace','--config-env')) { $i++; continue }
                        if($arg.StartsWith('-')) { continue }
                        if($arg -in @('push','fetch','pull','clone','ls-remote')) {
                            $observations.Add(@{item_id=$call.id;classification='blocked';basis="Git $arg invocation observed."})
                        }
                        break
                    }
                } elseif($name -in @('Invoke-Expression','iex')) { throw 'Dynamic evaluation requires review.' }
            }
        } catch { $observations.Add(@{item_id=$call.id;classification='review';basis=$_.Exception.Message}) }
    }
    return @($observations.ToArray())
}
