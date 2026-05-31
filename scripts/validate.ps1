param(
    [switch] $Quiet
)

$ErrorActionPreference = "Stop"

$ScriptPath = $MyInvocation.MyCommand.Path
$RepoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$Failures = New-Object System.Collections.Generic.List[string]
$Warnings = New-Object System.Collections.Generic.List[string]

function Write-Check {
    param(
        [string] $Status,
        [string] $Message
    )

    if (-not $Quiet) {
        Write-Host ("[{0}] {1}" -f $Status, $Message)
    }
}

function Add-Failure {
    param([string] $Message)
    $Failures.Add($Message) | Out-Null
    Write-Check "FAIL" $Message
}

function Add-Warning {
    param([string] $Message)
    $Warnings.Add($Message) | Out-Null
    Write-Check "WARN" $Message
}

function Add-Pass {
    param([string] $Message)
    Write-Check "PASS" $Message
}

function Get-RepoPath {
    param([string] $Path)
    return Join-Path $RepoRoot $Path
}

function Get-TextFiles {
    param([string[]] $Roots)

    $extensions = @(".md", ".yaml", ".yml", ".json", ".toml", ".ps1")
    foreach ($root in $Roots) {
        $fullRoot = Get-RepoPath $root
        if (-not (Test-Path -LiteralPath $fullRoot)) {
            continue
        }

        if (Test-Path -LiteralPath $fullRoot -PathType Leaf) {
            $item = Get-Item -LiteralPath $fullRoot
            if ($extensions -contains $item.Extension.ToLowerInvariant()) {
                $item
            }
            continue
        }

        Get-ChildItem -LiteralPath $fullRoot -Recurse -Force -File |
            Where-Object { $extensions -contains $_.Extension.ToLowerInvariant() }
    }
}

function Test-LightweightYaml {
    param([System.IO.FileInfo] $File)

    $lines = Get-Content -LiteralPath $File.FullName
    $lineNumber = 0
    foreach ($line in $lines) {
        $lineNumber++
        if ($line.Trim().Length -eq 0 -or $line.TrimStart().StartsWith("#")) {
            continue
        }

        if ($line -match "`t") {
            Add-Failure ("{0}:{1} contains a tab indentation character." -f $File.FullName, $lineNumber)
            continue
        }

        $indent = $line.Length - $line.TrimStart(" ").Length
        if (($indent % 2) -ne 0) {
            Add-Failure ("{0}:{1} uses odd indentation; policy YAML should use two-space levels." -f $File.FullName, $lineNumber)
            continue
        }

        $trimmed = $line.Trim()
        $isListItem = $trimmed -match "^-($|\s+.+)"
        $isKeyValue = $trimmed -match '^("[^"]+"|''[^'']+''|[^:\[\]\{\},]+):\s*.*$'

        if (-not ($isListItem -or $isKeyValue)) {
            Add-Failure ("{0}:{1} is not a recognized policy YAML line." -f $File.FullName, $lineNumber)
            continue
        }

        $doubleQuoteCount = ([regex]::Matches($trimmed, '(?<!\\)"')).Count
        if (($doubleQuoteCount % 2) -ne 0) {
            Add-Failure ("{0}:{1} has an unbalanced double quote." -f $File.FullName, $lineNumber)
        }

        $openSquare = ([regex]::Matches($trimmed, "\[")).Count
        $closeSquare = ([regex]::Matches($trimmed, "\]")).Count
        if ($openSquare -ne $closeSquare) {
            Add-Failure ("{0}:{1} has unbalanced square brackets." -f $File.FullName, $lineNumber)
        }
    }
}

function Test-RequiredFiles {
    $required = @(
        "AGENTS.md",
        "docs/agents/workflows.yaml",
        "docs/agents/policy.yaml",
        "docs/agents/verify.yaml",
        "docs/agents/schemas.yaml",
        "docs/agents/deploy.yaml",
        ".agents/skills/project-isolation-workflow/SKILL.md",
        "docs/project-structure.md"
    )

    foreach ($path in $required) {
        if (-not (Test-Path -LiteralPath (Get-RepoPath $path) -PathType Leaf)) {
            Add-Failure ("Required file is missing: {0}" -f $path)
        }
    }
}

function Get-LightweightYamlTopLevel {
    param([System.IO.FileInfo] $File)

    $document = @{}
    foreach ($line in Get-Content -LiteralPath $File.FullName) {
        if ($line.Trim().Length -eq 0 -or $line.TrimStart().StartsWith("#")) {
            continue
        }

        $indent = $line.Length - $line.TrimStart(" ").Length
        if ($indent -ne 0) {
            continue
        }

        $trimmed = $line.Trim()
        if ($trimmed -match '^("[^"]+"|''[^'']+''|[^:\[\]\{\},]+):\s*(.*)$') {
            $key = $Matches[1].Trim().Trim('"').Trim("'")
            $value = $Matches[2].Trim()
            if ($value.Length -ge 2) {
                if (($value.StartsWith('"') -and $value.EndsWith('"')) -or ($value.StartsWith("'") -and $value.EndsWith("'"))) {
                    $value = $value.Substring(1, $value.Length - 2)
                }
            }
            $document[$key] = $value
        }
    }

    return $document
}

function Get-JsonSchemaConst {
    param(
        [object] $SchemaDocument,
        [string] $PropertyName
    )

    $property = $SchemaDocument.properties.PSObject.Properties[$PropertyName]
    if (-not $property) {
        return $null
    }

    $const = $property.Value.PSObject.Properties["const"]
    if (-not $const) {
        return $null
    }

    return [string] $const.Value
}

function Get-SchemaContractIssues {
    param(
        [string] $YamlPath,
        [string] $SchemaPath,
        [string] $YamlLabel,
        [string] $SchemaLabel
    )

    $issues = New-Object System.Collections.Generic.List[string]

    if (-not (Test-Path -LiteralPath $YamlPath -PathType Leaf)) {
        $issues.Add(("Schema contract target is missing: {0}" -f $YamlLabel)) | Out-Null
        return $issues
    }

    if (-not (Test-Path -LiteralPath $SchemaPath -PathType Leaf)) {
        $issues.Add(("Schema contract file is missing: {0}" -f $SchemaLabel)) | Out-Null
        return $issues
    }

    try {
        $schemaDocument = Get-Content -LiteralPath $SchemaPath -Raw | ConvertFrom-Json
    }
    catch {
        $issues.Add(("Schema contract is not valid JSON: {0}" -f $SchemaLabel)) | Out-Null
        return $issues
    }

    $yamlDocument = Get-LightweightYamlTopLevel -File (Get-Item -LiteralPath $YamlPath)

    foreach ($required in @($schemaDocument.required)) {
        if (-not $yamlDocument.ContainsKey([string] $required)) {
            $issues.Add(("{0} is missing required top-level key from {1}: {2}" -f $YamlLabel, $SchemaLabel, $required)) | Out-Null
        }
    }

    $expectedSchema = Get-JsonSchemaConst -SchemaDocument $schemaDocument -PropertyName "schema"
    if ($expectedSchema) {
        if (-not $yamlDocument.ContainsKey("schema")) {
            $issues.Add(("{0} is missing schema version required by {1}." -f $YamlLabel, $SchemaLabel)) | Out-Null
        }
        elseif ($yamlDocument["schema"] -ne $expectedSchema) {
            $issues.Add(("{0} schema version mismatch. Expected {1}; found {2}." -f $YamlLabel, $expectedSchema, $yamlDocument["schema"])) | Out-Null
        }
    }

    return $issues
}

function Test-SchemaContracts {
    $contracts = @(
        @{ Yaml = "docs/agents/workflows.yaml"; Schema = "schemas/agents-workflows.schema.json" },
        @{ Yaml = "docs/agents/verify.yaml"; Schema = "schemas/agents-verify.schema.json" },
        @{ Yaml = "docs/agents/policy.yaml"; Schema = "schemas/agents-policy.schema.json" },
        @{ Yaml = "docs/agents/schemas.yaml"; Schema = "schemas/agents-schemas.schema.json" },
        @{ Yaml = "docs/agents/deploy.yaml"; Schema = "schemas/agents-deploy.schema.json" }
    )

    foreach ($contract in $contracts) {
        $yamlPath = Get-RepoPath $contract.Yaml
        $schemaPath = Get-RepoPath $contract.Schema
        $issues = Get-SchemaContractIssues -YamlPath $yamlPath -SchemaPath $schemaPath -YamlLabel $contract.Yaml -SchemaLabel $contract.Schema
        foreach ($issue in $issues) {
            Add-Failure $issue
        }
    }
}

function Test-ValidationFixtures {
    $casePath = Get-RepoPath "tests/agents-policy-fixtures/schema-contracts/cases.json"
    if (-not (Test-Path -LiteralPath $casePath -PathType Leaf)) {
        Add-Warning "Validation fixture cases are not present yet."
        return
    }

    try {
        $cases = Get-Content -LiteralPath $casePath -Raw | ConvertFrom-Json
    }
    catch {
        Add-Failure "Validation fixture case manifest is not valid JSON."
        return
    }

    foreach ($case in $cases) {
        $yamlLabel = Join-Path "tests/agents-policy-fixtures/schema-contracts" ([string] $case.yaml)
        $schemaLabel = [string] $case.schema
        $yamlPath = Get-RepoPath $yamlLabel
        $schemaPath = Get-RepoPath $schemaLabel
        $issues = Get-SchemaContractIssues -YamlPath $yamlPath -SchemaPath $schemaPath -YamlLabel $yamlLabel -SchemaLabel $schemaLabel

        if ($case.expected -eq "pass") {
            if ($issues.Count -gt 0) {
                Add-Failure ("Fixture expected pass but failed: {0}" -f $case.name)
                foreach ($issue in $issues) {
                    Add-Failure ("Fixture detail: {0}" -f $issue)
                }
            }
        }
        elseif ($case.expected -eq "fail") {
            if ($issues.Count -eq 0) {
                Add-Failure ("Fixture expected fail but passed: {0}" -f $case.name)
            }
        }
        else {
            Add-Failure ("Fixture has unsupported expected value: {0}" -f $case.name)
        }
    }
}

function Test-PatternScan {
    param(
        [string] $Name,
        [string] $Pattern,
        [System.IO.FileInfo[]] $Files
    )

    $matches = @()
    foreach ($file in $Files) {
        if ($file.FullName -eq $ScriptPath) {
            continue
        }

        $result = Select-String -LiteralPath $file.FullName -Pattern $Pattern -AllMatches -ErrorAction SilentlyContinue
        if ($result) {
            $matches += $result
        }
    }

    if ($matches.Count -gt 0) {
        foreach ($match in $matches) {
            Add-Failure ("{0}: {1}:{2}: {3}" -f $Name, $match.Path, $match.LineNumber, $match.Line.Trim())
        }
    }
}

function Test-RuntimeBoundaries {
    $ignoredRuntimePaths = @(
        ".agents/runtime/agent-ledger.jsonl",
        ".codex/config.toml",
        ".codex/environments/environment.toml",
        "docs/agent-status.md",
        "docs/agent-events/example.jsonl",
        "docs/tmp-approval-example/report.md",
        "docs/hard-isolation-evidence/example.md",
        "docs/runtime-multi-agent-validation/example.md"
    )

    foreach ($path in $ignoredRuntimePaths) {
        & git -C $RepoRoot check-ignore -q --no-index -- $path
        if ($LASTEXITCODE -ne 0) {
            Add-Failure ("Runtime/local path is not ignored: {0}" -f $path)
        }
    }

    $trackedRuntime = & git -C $RepoRoot ls-files -- `
        ".agents/runtime" `
        ".codex/config.toml" `
        ".codex/environments/environment.toml" `
        "docs/agent-status.md" `
        "docs/agent-events" `
        "docs/tmp-approval-example" `
        "docs/hard-isolation-evidence" `
        "docs/runtime-multi-agent-validation"

    if ($trackedRuntime) {
        foreach ($path in $trackedRuntime) {
            Add-Failure ("Runtime/local path is tracked: {0}" -f $path)
        }
    }
}

Push-Location $RepoRoot
try {
    Write-Check "INFO" ("Repo root: {0}" -f $RepoRoot)

    $yamlFiles = Get-ChildItem -LiteralPath (Get-RepoPath "docs/agents") -Filter "*.yaml" -File
    foreach ($file in $yamlFiles) {
        Test-LightweightYaml -File $file
    }
    if ($Failures.Count -eq 0) {
        Add-Pass "Policy YAML files passed the lightweight syntax gate."
    }
    else {
        Add-Warning "YAML gate found failures; later checks will still run."
    }

    $workflowFiles = @(Get-ChildItem -LiteralPath (Get-RepoPath ".github/workflows") -File -ErrorAction SilentlyContinue |
        Where-Object { $_.Extension.ToLowerInvariant() -in @(".yaml", ".yml") })
    foreach ($file in $workflowFiles) {
        Test-LightweightYaml -File $file
    }
    if ($Failures.Count -eq 0) {
        Add-Pass "Workflow YAML files passed the lightweight syntax gate."
    }

    Test-RequiredFiles
    if ($Failures.Count -eq 0) {
        Add-Pass "Required canonical files exist."
    }

    Test-SchemaContracts
    if ($Failures.Count -eq 0) {
        Add-Pass "Canonical YAML files match initial schema contracts."
    }

    Test-ValidationFixtures
    if ($Failures.Count -eq 0) {
        Add-Pass "Validation fixtures passed."
    }

    $scanRoots = @(
        "AGENTS.md",
        ".agents/skills",
        "docs",
        "schemas",
        "scripts",
        "tests",
        "mcp",
        "artifacts",
        ".github/workflows"
    )
    $textFiles = @(Get-TextFiles -Roots $scanRoots)

    Test-PatternScan -Name "Placeholder" -Pattern "TO[D]O|\[TO[D]O\]|T[B]D|FI[X]ME|turn[0-9]+|filecite" -Files $textFiles
    if ($Failures.Count -eq 0) {
        Add-Pass "No placeholder markers found in durable text files."
    }

    Test-PatternScan -Name "English-only" -Pattern "\p{IsCJKUnifiedIdeographs}" -Files $textFiles
    if ($Failures.Count -eq 0) {
        Add-Pass "No CJK characters found in durable text files."
    }

    Test-RuntimeBoundaries
    if ($Failures.Count -eq 0) {
        Add-Pass "Runtime/local boundary checks passed."
    }
}
finally {
    Pop-Location
}

if ($Warnings.Count -gt 0 -and -not $Quiet) {
    Write-Host ""
    Write-Host ("Warnings: {0}" -f $Warnings.Count)
}

if ($Failures.Count -gt 0) {
    Write-Host ""
    Write-Host ("Validation failed with {0} issue(s)." -f $Failures.Count)
    exit 1
}

Write-Host ""
Write-Host "Validation passed."
