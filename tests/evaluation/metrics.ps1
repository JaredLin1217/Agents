function Get-Median([double[]]$Values) {
    if(-not $Values.Count) { return $null }
    $sorted=@($Values|Sort-Object); $mid=[int][Math]::Floor($sorted.Count/2)
    if($sorted.Count%2) { return $sorted[$mid] }
    return ($sorted[$mid-1]+$sorted[$mid])/2
}
function Test-MeasurableSample($Sample) {
    return ($Sample.passed -and $Sample.event_parse_errors -eq 0 -and
        $Sample.Contains('environment_blocked') -and -not $Sample.environment_blocked -and
        $Sample.boundary_violations.Count -eq 0)
}
function Get-EvaluationMetrics($Run) {
    $expectedCases=@('answer','local-fix','cross-module','diagnosis','style','release','deploy','rollback','recovery','knowledge','stale-conflict','untrusted-input')
    $lookup=@{}
    foreach($sample in $Run.samples) {
        if($sample.case -notin $expectedCases -or $sample.repetition -notin 1..3 -or $sample.group -notin @('baseline','candidate')) { throw 'Unknown evaluation sample.' }
        $key="$($sample.case)|$($sample.repetition)|$($sample.group)"
        if($lookup.ContainsKey($key)) { throw "Duplicate evaluation sample: $key" }; $lookup[$key]=$sample
    }
    $baselineInput=@(); $candidateInput=@(); $baselineTools=@(); $candidateTools=@(); $pairCount=0; $missing=0
    foreach($case in $expectedCases) {
        foreach($rep in 1..3) {
            $a=$lookup["$case|$rep|baseline"]; $b=$lookup["$case|$rep|candidate"]
            if($null -eq $a -or $null -eq $b -or -not(Test-MeasurableSample $a) -or -not(Test-MeasurableSample $b)) { continue }
            $pairCount++
            if($null -eq $a.usage -or $null -eq $b.usage -or $null -eq $a.usage.input_tokens -or
                $null -eq $b.usage.input_tokens -or $null -eq $a.tool_calls -or $null -eq $b.tool_calls) { $missing++; continue }
            if($a.usage.input_tokens -lt 0 -or $b.usage.input_tokens -lt 0 -or $a.tool_calls -lt 0 -or $b.tool_calls -lt 0) { throw 'Negative evaluation counters.' }
            $baselineInput+=$a.usage.input_tokens; $candidateInput+=$b.usage.input_tokens
            $baselineTools+=$a.tool_calls; $candidateTools+=$b.tool_calls
        }
    }
    $inputBase=Get-Median $baselineInput; $inputCandidate=Get-Median $candidateInput
    $toolsBase=Get-Median $baselineTools; $toolsCandidate=Get-Median $candidateTools
    $inputReduction=if($null -ne $inputBase -and $inputBase -gt 0){100*(1-$inputCandidate/$inputBase)}else{$null}
    $toolReduction=if($null -ne $toolsBase -and $toolsBase -gt 0){100*(1-$toolsCandidate/$toolsBase)}else{$null}
    $complete=$Run.status -eq 'completed' -and $Run.planned_samples -eq 72 -and $lookup.Count -eq 72
    $candidate=@($Run.samples|Where-Object group -EQ 'candidate')
    $candidatePass=@($candidate|Where-Object { Test-MeasurableSample $_ }).Count
    $badBoundary=@($Run.samples|Where-Object {$_.boundary_violations.Count}).Count
    $efficiency=$null -ne $inputReduction -and $inputReduction -ge 30 -and $null -ne $toolReduction -and $toolReduction -ge 20 -and $missing -eq 0
    return [ordered]@{complete_72_samples=[bool]$complete;candidate_samples=$candidate.Count;candidate_passed=$candidatePass;
        candidate_failed=($candidate.Count-$candidatePass);boundary_failed_samples=$badBoundary;successful_pairs=$pairCount;missing_counter_pairs=$missing;
        baseline_input_median=$inputBase;candidate_input_median=$inputCandidate;input_reduction_percent=$inputReduction;
        baseline_tool_median=$toolsBase;candidate_tool_median=$toolsCandidate;tool_reduction_percent=$toolReduction;
        acceptance_passed=[bool]($complete -and $candidatePass -eq 36 -and $badBoundary -eq 0 -and $efficiency);
        scope='Model task and efficiency gates only; offline engineering gates remain separately required.'}
}
