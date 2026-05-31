param(
    [switch] $Quiet,
    [switch] $Full
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

function Convert-AgentLedgerEventForValidation {
    param([pscustomobject] $Event)

    $normalized = [ordered]@{}
    foreach ($property in $Event.PSObject.Properties) {
        $normalized[$property.Name] = $property.Value
    }

    $aliases = @{
        time       = "ts"
        runtime_id = "agent_id"
        agent      = "agent_id"
        controller = "controller_id"
        scope      = "read_scope"
    }
    foreach ($alias in $aliases.Keys) {
        $canonical = $aliases[$alias]
        if ($normalized.Contains($alias) -and -not $normalized.Contains($canonical)) {
            $normalized[$canonical] = $normalized[$alias]
        }
    }

    return [pscustomobject]$normalized
}

function Get-RepoPath {
    param([string] $Path)
    return Join-Path $RepoRoot $Path
}

function Get-SourceSpecificLiterals {
    $literals = New-Object 'System.Collections.Generic.HashSet[string]'
    foreach ($literal in @($RepoRoot.Path, (Split-Path -Leaf $RepoRoot.Path))) {
        if (-not [string]::IsNullOrWhiteSpace($literal) -and $literal -ne "Agents") {
            [void] $literals.Add($literal)
        }
    }

    $remoteUrl = (& git -C $RepoRoot remote get-url origin 2>$null)
    if (-not [string]::IsNullOrWhiteSpace($remoteUrl)) {
        [void] $literals.Add($remoteUrl)
        if ($remoteUrl -match "[:/]([^/]+)/([^/]+?)(\.git)?$") {
            [void] $literals.Add($Matches[1])
            [void] $literals.Add(("{0}/{1}" -f $Matches[1], $Matches[2]))
            [void] $literals.Add(("{0}.git" -f $Matches[2]))
        }
    }

    return @($literals)
}

function Get-TextFiles {
    param([string[]] $Roots)

    $extensions = @(".md", ".yaml", ".yml", ".json", ".toml", ".ps1", ".txt")
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
        "docs/agents/mcp.yaml",
        "docs/agents/version.yaml",
        ".agents/skills/project-isolation-workflow/SKILL.md",
        "docs/project-structure.md",
        "scripts/deploy-agents-workflow.ps1"
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

function Get-LightweightYamlPathValues {
    param([System.IO.FileInfo] $File)

    $paths = @{}
    $stack = @{}

    foreach ($line in Get-Content -LiteralPath $File.FullName) {
        if ($line.Trim().Length -eq 0 -or $line.TrimStart().StartsWith("#")) {
            continue
        }

        $indent = $line.Length - $line.TrimStart(" ").Length
        $level = [int] ($indent / 2)
        $trimmed = $line.Trim()

        if ($trimmed -match '^- ') {
            continue
        }

        if ($trimmed -match '^("[^"]+"|''[^'']+''|[^:\[\]\{\},]+):\s*(.*)$') {
            $key = $Matches[1].Trim().Trim('"').Trim("'")
            $value = $Matches[2].Trim()

            foreach ($existingLevel in @($stack.Keys)) {
                if ([int] $existingLevel -ge $level) {
                    $stack.Remove($existingLevel)
                }
            }

            $stack[$level] = $key
            $orderedKeys = @()
            foreach ($stackLevel in ($stack.Keys | Sort-Object { [int] $_ })) {
                $orderedKeys += $stack[$stackLevel]
            }

            $path = $orderedKeys -join "."
            if ($value.Length -ge 2) {
                if (($value.StartsWith('"') -and $value.EndsWith('"')) -or ($value.StartsWith("'") -and $value.EndsWith("'"))) {
                    $value = $value.Substring(1, $value.Length - 2)
                }
            }
            $paths[$path] = $value
        }
    }

    return $paths
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

    $yamlPathValues = Get-LightweightYamlPathValues -File (Get-Item -LiteralPath $YamlPath)
    $requiredPathsProperty = $schemaDocument.PSObject.Properties["x-required-paths"]
    if ($requiredPathsProperty) {
        foreach ($requiredPath in @($requiredPathsProperty.Value)) {
            if (-not $yamlPathValues.ContainsKey([string] $requiredPath)) {
                $issues.Add(("{0} is missing required nested path from {1}: {2}" -f $YamlLabel, $SchemaLabel, $requiredPath)) | Out-Null
            }
        }
    }

    $requiredValuesProperty = $schemaDocument.PSObject.Properties["x-required-values"]
    if ($requiredValuesProperty) {
        foreach ($requiredValue in @($requiredValuesProperty.Value)) {
            $path = [string] $requiredValue.path
            $expected = [string] $requiredValue.value
            if (-not $yamlPathValues.ContainsKey($path)) {
                $issues.Add(("{0} is missing required value path from {1}: {2}" -f $YamlLabel, $SchemaLabel, $path)) | Out-Null
            }
            elseif ([string] $yamlPathValues[$path] -ne $expected) {
                $issues.Add(("{0} value mismatch at {1}. Expected {2}; found {3}." -f $YamlLabel, $path, $expected, $yamlPathValues[$path])) | Out-Null
            }
        }
    }

    $requiredContainsProperty = $schemaDocument.PSObject.Properties["x-required-contains"]
    if ($requiredContainsProperty) {
        foreach ($requiredContains in @($requiredContainsProperty.Value)) {
            $path = [string] $requiredContains.path
            if (-not $yamlPathValues.ContainsKey($path)) {
                $issues.Add(("{0} is missing required contains path from {1}: {2}" -f $YamlLabel, $SchemaLabel, $path)) | Out-Null
                continue
            }

            $actual = [string] $yamlPathValues[$path]
            foreach ($needle in @($requiredContains.contains)) {
                if (-not $actual.Contains([string] $needle)) {
                    $issues.Add(("{0} value at {1} must contain {2}." -f $YamlLabel, $path, $needle)) | Out-Null
                }
            }
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
        @{ Yaml = "docs/agents/deploy.yaml"; Schema = "schemas/agents-deploy.schema.json" },
        @{ Yaml = "docs/agents/mcp.yaml"; Schema = "schemas/agents-mcp.schema.json" },
        @{ Yaml = "docs/agents/version.yaml"; Schema = "schemas/agents-version.schema.json" }
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
    $casePath = Get-RepoPath "tests/agents-governance-fixtures/schema-contracts/cases.json"
    if (-not (Test-Path -LiteralPath $casePath -PathType Leaf)) {
        Add-Failure "Validation fixture cases are missing."
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
        $yamlLabel = Join-Path "tests/agents-governance-fixtures/schema-contracts" ([string] $case.yaml)
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
        ".agents/docs/agent-status.md",
        ".agents/docs/agent-events/example.jsonl",
        "docs/tmp-approval-example/report.md",
        ".agents/docs/tmp-approval-example/report.md",
        "docs/hard-isolation-evidence/example.md",
        ".agents/docs/hard-isolation-evidence/example.md",
        "docs/runtime-multi-agent-validation/example.md",
        ".agents/docs/runtime-multi-agent-validation/example.md"
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
        ".agents/docs/agent-status.md" `
        ".agents/docs/agent-events" `
        "docs/tmp-approval-example" `
        ".agents/docs/tmp-approval-example" `
        "docs/hard-isolation-evidence" `
        ".agents/docs/hard-isolation-evidence" `
        "docs/runtime-multi-agent-validation" `
        ".agents/docs/runtime-multi-agent-validation"

    if ($trackedRuntime) {
        foreach ($path in $trackedRuntime) {
            Add-Failure ("Runtime/local path is tracked: {0}" -f $path)
        }
    }
}

function Test-GitDiffCheck {
    $startFailureCount = $Failures.Count
    $previousErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
        $output = & git -C $RepoRoot diff --check 2>&1
        $exitCode = $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $previousErrorActionPreference
    }
    if ($exitCode -ne 0) {
        foreach ($line in $output) {
            Add-Failure ("Git diff check failed: {0}" -f $line)
        }
    }

    if ($Failures.Count -eq $startFailureCount) {
        Add-Pass "Git diff hygiene checks passed."
    }
}

function Test-LineEndings {
    $startFailureCount = $Failures.Count
    $textFiles = @(Get-TextFiles -Roots @(
        "AGENTS.md",
        ".agents/skills",
        "docs",
        "schemas",
        "scripts",
        "tests",
        "mcp",
        "artifacts",
        ".github/workflows"
    ))

    foreach ($file in $textFiles) {
        $bytes = [System.IO.File]::ReadAllBytes($file.FullName)
        for ($i = 0; $i -lt ($bytes.Length - 1); $i++) {
            if ($bytes[$i] -eq 13 -and $bytes[$i + 1] -eq 10) {
                Add-Failure ("Text file uses CRLF line endings; expected LF: {0}" -f $file.FullName)
                break
            }
        }
    }

    if ($Failures.Count -eq $startFailureCount) {
        Add-Pass "Line-ending readiness checks passed."
    }
}

function Get-IntendedRepoFiles {
    $files = @(
        & git -C $RepoRoot ls-files
        & git -C $RepoRoot ls-files --others --exclude-standard
    ) | Where-Object { $_ } | Sort-Object -Unique

    return @($files)
}

function Test-ExactPairs {
    $startFailureCount = $Failures.Count
    $pairs = @(
        @("docs/agent-assignment.template.md", "docs/templates/agents/agent-assignment.template.md"),
        @("docs/agent-status.template.md", "docs/templates/agents/agent-status.template.md"),
        @("docs/agent-event.template.md", "docs/templates/agents/agent-event.template.md"),
        @("docs/controller-lease.template.md", "docs/templates/agents/controller-lease.template.md"),
        @("docs/hard-isolation-evidence.template.md", "docs/templates/agents/hard-isolation-evidence.template.md"),
        @("docs/runtime-multi-agent-validation.template.md", "docs/templates/agents/runtime-multi-agent-validation.template.md"),
        @("docs/memory-entry.template.md", "docs/templates/agents/memory-entry.template.md"),
        @("docs/memory/entries/README.md", "docs/templates/agents/memory-entries-README.md"),
        @(".agents/skills/project-isolation-workflow/agents/openai.yaml", "docs/templates/agents/skills/project-isolation-workflow/agents/openai.yaml"),
        @("AGENTS.md", "docs/templates/agents/AGENTS.md"),
        @(".agents/skills/project-isolation-workflow/SKILL.md", "docs/templates/agents/skills/project-isolation-workflow/SKILL.md"),
        @("docs/agents/policy.yaml", "docs/templates/agents/agents/policy.yaml"),
        @("docs/agents/workflows.yaml", "docs/templates/agents/agents/workflows.yaml"),
        @("docs/agents/schemas.yaml", "docs/templates/agents/agents/schemas.yaml"),
        @("docs/agents/deploy.yaml", "docs/templates/agents/agents/deploy.yaml"),
        @("docs/agents/mcp.yaml", "docs/templates/agents/agents/mcp.yaml"),
        @("docs/agents/version.yaml", "docs/templates/agents/agents/version.yaml"),
        @("docs/agents/verify.yaml", "docs/templates/agents/agents/verify.yaml"),
        @("docs/runbooks/agents-deployment.md", "docs/templates/agents/agents-deployment.md"),
        @("docs/runbooks/isolation-audit.md", "docs/templates/agents/isolation-audit.md"),
        @("docs/runbooks/multi-agent-workflow.md", "docs/templates/agents/multi-agent-workflow.md"),
        @("docs/runbooks/repository-maintenance.md", "docs/templates/agents/repository-maintenance.md"),
        @("docs/runbooks/session-handoff.md", "docs/templates/agents/session-handoff.md"),
        @("docs/runbooks/skill-authoring.md", "docs/templates/agents/skill-authoring.md"),
        @("docs/runbooks/task-closeout.md", "docs/templates/agents/task-closeout.md")
    )

    foreach ($pair in $pairs) {
        $left = Get-RepoPath $pair[0]
        $right = Get-RepoPath $pair[1]
        if (-not (Test-Path -LiteralPath $left -PathType Leaf)) {
            Add-Failure ("Exact-pair source missing: {0}" -f $pair[0])
            continue
        }
        if (-not (Test-Path -LiteralPath $right -PathType Leaf)) {
            Add-Failure ("Exact-pair template missing: {0}" -f $pair[1])
            continue
        }
        $leftHash = (Get-FileHash -LiteralPath $left -Algorithm SHA256).Hash
        $rightHash = (Get-FileHash -LiteralPath $right -Algorithm SHA256).Hash
        if ($leftHash -ne $rightHash) {
            Add-Failure ("Exact-pair drift: {0} != {1}" -f $pair[0], $pair[1])
        }
    }

    if ($Failures.Count -eq $startFailureCount) {
        Add-Pass "Exact-pair drift checks passed."
    }
}

function Test-TemplateCoverage {
    $startFailureCount = $Failures.Count
    $allowed = New-Object 'System.Collections.Generic.HashSet[string]'
    $allowedItems = @(
        "docs/templates/agents/agent-assignment.template.md",
        "docs/templates/agents/agent-status.template.md",
        "docs/templates/agents/agent-event.template.md",
        "docs/templates/agents/controller-lease.template.md",
        "docs/templates/agents/hard-isolation-evidence.template.md",
        "docs/templates/agents/runtime-multi-agent-validation.template.md",
        "docs/templates/agents/memory-entry.template.md",
        "docs/templates/agents/memory-entries-README.md",
        "docs/templates/agents/skills/project-isolation-workflow/agents/openai.yaml",
        "docs/templates/agents/AGENTS.md",
        "docs/templates/agents/skills/project-isolation-workflow/SKILL.md",
        "docs/templates/agents/agents/policy.yaml",
        "docs/templates/agents/agents/workflows.yaml",
        "docs/templates/agents/agents/schemas.yaml",
        "docs/templates/agents/agents/deploy.yaml",
        "docs/templates/agents/agents/mcp.yaml",
        "docs/templates/agents/agents/version.yaml",
        "docs/templates/agents/agents/verify.yaml",
        "docs/templates/agents/agents-deployment.md",
        "docs/templates/agents/isolation-audit.md",
        "docs/templates/agents/multi-agent-workflow.md",
        "docs/templates/agents/repository-maintenance.md",
        "docs/templates/agents/session-handoff.md",
        "docs/templates/agents/skill-authoring.md",
        "docs/templates/agents/task-closeout.md",
        "docs/templates/agents/README.md",
        "docs/templates/agents/gitignore.fragment",
        "docs/templates/agents/project-memory.md",
        "docs/templates/agents/project-structure.md",
        "docs/templates/agents/memory-index.md"
    )
    foreach ($item in $allowedItems) {
        [void] $allowed.Add($item)
    }

    $templateFiles = Get-IntendedRepoFiles | Where-Object { $_ -like "docs/templates/agents/*" }
    foreach ($path in $templateFiles) {
        $normalized = $path.Replace("\", "/")
        if (-not $allowed.Contains($normalized)) {
            Add-Failure ("Template bundle file is not covered by exact-pair or cleanliness list: {0}" -f $normalized)
        }
    }

    if ($Failures.Count -eq $startFailureCount) {
        Add-Pass "Template bundle coverage checks passed."
    }
}

function Test-TemplateSourceNeutrality {
    $startFailureCount = $Failures.Count
    $literals = Get-SourceSpecificLiterals
    $templateFiles = @(Get-TextFiles -Roots @("docs/templates/agents"))

    foreach ($literal in $literals) {
        foreach ($file in $templateFiles) {
            $match = Select-String -LiteralPath $file.FullName -Pattern $literal -SimpleMatch -Quiet -ErrorAction SilentlyContinue
            if ($match) {
                Add-Failure ("Template source-neutrality check found provider literal in {0}: {1}" -f $file.FullName, $literal)
            }
        }
    }

    if ($Failures.Count -eq $startFailureCount) {
        Add-Pass "Template source-neutrality checks passed."
    }
}

function Test-DeployManifestIntegrity {
    $startFailureCount = $Failures.Count
    $deployPaths = @("docs/agents/deploy.yaml", "docs/templates/agents/agents/deploy.yaml")
    $deploymentScriptContent = Get-Content -LiteralPath (Get-RepoPath "scripts/deploy-agents-workflow.ps1") -Raw
    $scriptModes = @()
    $modeSetMatch = [regex]::Match($deploymentScriptContent, '\[ValidateSet\(([^)]*)\)\]\s*\r?\n\s*\[string\]\s*\$Mode')
    if ($modeSetMatch.Success) {
        $scriptModes = @([regex]::Matches($modeSetMatch.Groups[1].Value, '"([^"]+)"') | ForEach-Object { $_.Groups[1].Value })
    }
    else {
        Add-Failure "Deployment script mode ValidateSet is missing."
    }
    $requiredBlocklist = @(
        @{ Manifest = ".agents/runtime/"; Script = ".agents/runtime/" },
        @{ Manifest = "docs/agent-status.md"; Script = "docs/agent-status.md" },
        @{ Manifest = "docs/agent-events/"; Script = "docs/agent-events/" },
        @{ Manifest = ".agents/docs/agent-status.md"; Script = ".agents/docs/agent-status.md" },
        @{ Manifest = ".agents/docs/agent-events/"; Script = ".agents/docs/agent-events/" },
        @{ Manifest = "docs/tmp-approval-*/"; Script = "docs/tmp-approval-" },
        @{ Manifest = ".agents/docs/tmp-approval-*/"; Script = ".agents/docs/tmp-approval-" },
        @{ Manifest = "docs/hard-isolation-evidence/"; Script = "docs/hard-isolation-evidence/" },
        @{ Manifest = ".agents/docs/hard-isolation-evidence/"; Script = ".agents/docs/hard-isolation-evidence/" },
        @{ Manifest = "docs/runtime-multi-agent-validation/"; Script = "docs/runtime-multi-agent-validation/" },
        @{ Manifest = ".agents/docs/runtime-multi-agent-validation/"; Script = ".agents/docs/runtime-multi-agent-validation/" },
        @{ Manifest = ".codex/config.toml"; Script = ".codex/config.toml" },
        @{ Manifest = ".codex/environments/environment.toml"; Script = ".codex/environments/environment.toml" },
        @{ Manifest = ".git/"; Script = ".git/" }
    )

    foreach ($path in $deployPaths) {
        $fullPath = Get-RepoPath $path
        $content = Get-Content -LiteralPath $fullPath
        if (-not ($content | Where-Object { $_ -match "^steps:" })) {
            Add-Failure ("Deploy manifest has no top-level steps: {0}" -f $path)
        }
        if ($content | Where-Object { $_ -match "^  steps:" }) {
            Add-Failure ("Deploy manifest contains nested steps: {0}" -f $path)
        }

        $fromPaths = @()
        $toPaths = @()
        $deployableGroups = @()
        $declaredModes = @()
        $modeNames = @()
        $modeGroupRefs = @()
        $section = $null
        foreach ($line in $content) {
            if ($line -match "^deployment_modes:") {
                $section = "deployment_modes"
                continue
            }
            if ($line -match "^mode_composition:") {
                $section = "mode_composition"
                continue
            }
            if ($line -match "^deployable_by_mode:") {
                $section = "deployable_by_mode"
                continue
            }
            if ($line -match "^[a-zA-Z_]+:") {
                $section = $null
            }

            if ($section -eq "deployment_modes" -and $line -match '^\s{2}([a-zA-Z0-9_]+):') {
                $declaredModes += $Matches[1]
            }
            elseif ($section -eq "mode_composition" -and $line -match '^\s{2}([a-zA-Z0-9_]+):\s*\[(.+)\]') {
                $modeNames += $Matches[1]
                $modeGroupRefs += @($Matches[2] -split "," | ForEach-Object { $_.Trim().Trim('"') } | Where-Object { $_.Length -gt 0 })
            }
            elseif ($section -eq "deployable_by_mode" -and $line -match '^\s{2}([a-zA-Z0-9_]+):') {
                $deployableGroups += $Matches[1]
            }

            if ($line -match '^\s+- from: "([^"]+)"') {
                $fromPaths += $Matches[1]
            }
            elseif ($line -match '^\s+to: "([^"]+)"') {
                $toPaths += $Matches[1]
            }
        }

        foreach ($from in $fromPaths) {
            if (-not (Test-Path -LiteralPath (Get-RepoPath $from) -PathType Leaf)) {
                Add-Failure ("Deploy source path is missing in {0}: {1}" -f $path, $from)
            }
        }

        $duplicateFrom = $fromPaths | Group-Object | Where-Object { $_.Count -gt 1 }
        foreach ($group in $duplicateFrom) {
            Add-Failure ("Deploy source path is duplicated in {0}: {1}" -f $path, $group.Name)
        }

        $nonAppendToPaths = $toPaths | Where-Object { $_ -notlike "*append/adapt*" }
        $duplicateTo = $nonAppendToPaths | Group-Object | Where-Object { $_.Count -gt 1 }
        foreach ($group in $duplicateTo) {
            Add-Failure ("Deploy destination path is duplicated in {0}: {1}" -f $path, $group.Name)
        }

        foreach ($group in ($modeGroupRefs | Select-Object -Unique)) {
            if ($deployableGroups -notcontains $group) {
                Add-Failure ("Deploy mode_composition references missing deployable_by_mode group in {0}: {1}" -f $path, $group)
            }
            if (-not $deploymentScriptContent.Contains(('"{0}"' -f $group))) {
                Add-Failure ("Deployment script mode groups are not synchronized with deploy manifest group: {0}" -f $group)
            }
        }

        foreach ($group in ($deployableGroups | Select-Object -Unique)) {
            if ($modeGroupRefs -notcontains $group) {
                Add-Failure ("Deploy deployable_by_mode group is not reachable from mode_composition in {0}: {1}" -f $path, $group)
            }
        }

        foreach ($mode in ($declaredModes | Select-Object -Unique)) {
            if ($modeNames -notcontains $mode) {
                Add-Failure ("Deploy deployment_modes entry is missing mode_composition in {0}: {1}" -f $path, $mode)
            }
            if ($scriptModes -notcontains $mode) {
                Add-Failure ("Deployment script ValidateSet is missing deploy manifest mode: {0}" -f $mode)
            }
        }

        foreach ($mode in ($modeNames | Select-Object -Unique)) {
            if ($declaredModes -notcontains $mode) {
                Add-Failure ("Deploy mode_composition entry is missing deployment_modes entry in {0}: {1}" -f $path, $mode)
            }
            if (-not $deploymentScriptContent.Contains(('"{0}"' -f $mode))) {
                Add-Failure ("Deployment script mode names are not synchronized with deploy manifest mode: {0}" -f $mode)
            }
        }

        foreach ($mode in ($scriptModes | Select-Object -Unique)) {
            if ($declaredModes -notcontains $mode) {
                Add-Failure ("Deployment script ValidateSet has a mode missing from deploy manifest: {0}" -f $mode)
            }
        }

        foreach ($block in $requiredBlocklist) {
            $required = $block.Manifest
            if (-not ($content | Where-Object { $_ -match [regex]::Escape($required) })) {
                Add-Failure ("Deploy blocklist is missing required path in {0}: {1}" -f $path, $required)
            }
            if (-not $deploymentScriptContent.Contains($block.Script)) {
                Add-Failure ("Deployment script blocklist is not synchronized with deploy manifest path: {0}" -f $required)
            }
        }
    }

    if ($Failures.Count -eq $startFailureCount) {
        Add-Pass "Deploy manifest integrity checks passed."
    }
}

function Test-DeploymentScriptSafety {
    $startFailureCount = $Failures.Count
    $path = "scripts/deploy-agents-workflow.ps1"
    $fullPath = Get-RepoPath $path
    if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) {
        Add-Failure "Deployment entry point is missing: scripts/deploy-agents-workflow.ps1"
        return
    }

    $content = Get-Content -LiteralPath $fullPath -Raw
    $requiredMarkers = @(
        "Assert-RelativeDeployPath",
        "Assert-InsideRoot",
        "Test-PathInsideRoot",
        "Confirm-SourceAllowed",
        "Assert-DeployWriteAllowed",
        "requires -Upgrade",
        "Get-SourceSpecificLiterals",
        "Assert-NoSourceLiteral",
        "Assert-SelfTestMissing",
        "Assert-SelfTestContent",
        "Assert-SelfTestContains",
        "Assert-SelfTestTextContains",
        "Assert-SelfTestBlockedDeployPath",
        "CreateTarget",
        "SelfTest",
        "Validation Summary",
        "Target files planned for create/update",
        "Existing target files already current",
        "Refusing to write into the provider/source repo"
    )
    foreach ($marker in $requiredMarkers) {
        if (-not $content.Contains($marker)) {
            Add-Failure ("Deployment script is missing safety marker: {0}" -f $marker)
        }
    }

    $forbiddenPatterns = @(
        "#requires",
        "RunAsAdministrator",
        "Start-Process",
        "Verb RunAs",
        "sudo ",
        "chmod ",
        "chown ",
        "icacls",
        "takeown",
        "Set-Acl",
        "Get-Acl",
        "attrib ",
        "git reset --hard",
        "git checkout --"
    )
    foreach ($pattern in $forbiddenPatterns) {
        if ($content -match [regex]::Escape($pattern)) {
            Add-Failure ("Deployment script contains forbidden local repair or destructive pattern: {0}" -f $pattern)
        }
    }

    if ($Failures.Count -eq $startFailureCount) {
        Add-Pass "Deployment script safety checks passed."
    }
}

function Test-DeploymentSelfTest {
    $startFailureCount = $Failures.Count
    $previousErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
        $output = & (Get-RepoPath "scripts/deploy-agents-workflow.ps1") -SelfTest -Quiet 2>&1
        $exitCode = $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $previousErrorActionPreference
    }

    if ($exitCode -ne 0) {
        Add-Failure "Deployment self-test failed."
        foreach ($line in $output) {
            Add-Failure ("Deployment self-test detail: {0}" -f $line)
        }
    }
    elseif (@($output).Count -gt 0) {
        Add-Failure "Deployment self-test quiet mode produced output."
        foreach ($line in $output) {
            Add-Failure ("Deployment self-test quiet output: {0}" -f $line)
        }
    }

    if ($Failures.Count -eq $startFailureCount) {
        Add-Pass "Deployment self-test passed."
    }
}

function Test-MultiAgentWorkflowIntegrity {
    $startFailureCount = $Failures.Count
    $workflowPaths = @("docs/agents/workflows.yaml", "docs/templates/agents/agents/workflows.yaml")
    $workflowMarkers = @(
        "multi_agent_runtime:",
        "do_not_trigger_for:",
        "lifecycle_checks:",
        "before:",
        "during:",
        "after:",
        "ownership:",
        "hard_fail:",
        "ledger_missing_or_cleared",
        "report_dedupe:",
        "scoring_batches:",
        "convergence:",
        "delegated_deployment:",
        "deployment_worker",
        "deployed_file_set"
    )
    foreach ($path in $workflowPaths) {
        $content = Get-Content -LiteralPath (Get-RepoPath $path) -Raw
        foreach ($marker in $workflowMarkers) {
            if (-not $content.Contains($marker)) {
                Add-Failure ("Multi-agent workflow marker is missing in {0}: {1}" -f $path, $marker)
            }
        }
    }

    $schemaPaths = @("docs/agents/schemas.yaml", "docs/templates/agents/agents/schemas.yaml")
    $schemaMarkers = @(
        "assignment:",
        "ownership_matrix:",
        "employee_final_report:",
        "agent_status_snapshot:",
        "agent_event:",
        "agent_ledger_event:",
        "canonical_fields:",
        "compatibility_aliases:",
        "controller_lease:",
        "runtime_multi_agent_validation:",
        "Roster snapshot version",
        "Ownership matrix status",
        "Final report matched runtime id",
        "Git status after employee work"
    )
    foreach ($path in $schemaPaths) {
        $content = Get-Content -LiteralPath (Get-RepoPath $path) -Raw
        foreach ($marker in $schemaMarkers) {
            if (-not $content.Contains($marker)) {
                Add-Failure ("Multi-agent schema marker is missing in {0}: {1}" -f $path, $marker)
            }
        }
    }

    if ($Failures.Count -eq $startFailureCount) {
        Add-Pass "Multi-agent workflow integrity checks passed."
    }
}

function Test-AgentLedgerCompatibility {
    $startFailureCount = $Failures.Count
    $samples = @(
        '{"ts":"2026-05-31T00:00:00Z","event":"completed","agent_id":"agent-1","mode":"session-managed","role":"explorer","task":"audit","status":"completed"}',
        '{"time":"2026-05-31T00:00:00Z","event":"completed","runtime_id":"agent-2","mode":"session-managed","role":"explorer","task":"audit","status":"completed"}',
        '{"ts":"2026-05-31T00:00:00Z","event":"closed","agent":"agent-3","controller":"codex","scope":"read-only audit","mode":"session-managed","role":"explorer","task":"audit"}'
    )
    $requiredFields = @("ts", "event", "agent_id", "mode", "role", "task")

    foreach ($sample in $samples) {
        try {
            $event = $sample | ConvertFrom-Json
        }
        catch {
            Add-Failure ("Agent ledger sample is invalid JSON: {0}" -f $sample)
            continue
        }

        $normalized = Convert-AgentLedgerEventForValidation -Event $event
        foreach ($field in $requiredFields) {
            $property = $normalized.PSObject.Properties[$field]
            if ($null -eq $property -or [string]::IsNullOrWhiteSpace([string]$property.Value)) {
                Add-Failure ("Agent ledger compatibility sample is missing canonical field after normalization: {0}" -f $field)
            }
        }
    }

    if ($Failures.Count -eq $startFailureCount) {
        Add-Pass "Agent ledger compatibility checks passed."
    }
}

function Test-EvidenceTemplateSchemaCoverage {
    $startFailureCount = $Failures.Count
    $schemaContent = Get-Content -LiteralPath (Get-RepoPath "docs/agents/schemas.yaml") -Raw

    function Get-RequiredFields {
        param(
            [string] $Section,
            [string] $NextSection
        )
        $sectionStart = $schemaContent.IndexOf(("{0}:" -f $Section))
        $sectionEnd = $schemaContent.IndexOf(("{0}:" -f $NextSection), $sectionStart + 1)
        if ($sectionStart -lt 0 -or $sectionEnd -lt 0) {
            Add-Failure ("Schema section boundary is missing: {0} -> {1}" -f $Section, $NextSection)
            return @()
        }

        $sectionText = $schemaContent.Substring($sectionStart, $sectionEnd - $sectionStart)
        return [regex]::Matches($sectionText, '^\s*-\s+"([^"]+)"', [System.Text.RegularExpressions.RegexOptions]::Multiline) |
            ForEach-Object { $_.Groups[1].Value }
    }

    function Get-TemplateEvidenceFields {
        param([string] $Path)

        $groupPrefixes = @(
            "Scope",
            "Runtime",
            "Live evidence",
            "Ledger/roster/lease",
            "Assignment proof",
            "Ownership",
            "Final report",
            "Boundary",
            "Work result",
            "Events",
            "Close/cleanup",
            "Result"
        )
        $fields = New-Object 'System.Collections.Generic.HashSet[string]'
        $content = Get-Content -LiteralPath (Get-RepoPath $Path)
        foreach ($line in $content) {
            if ($line -notmatch "^\s*-\s+(.+)$") {
                continue
            }

            foreach ($part in ($Matches[1] -split "\|")) {
                $field = $part.Trim()
                if ([string]::IsNullOrWhiteSpace($field)) {
                    continue
                }

                if ($field -match "^([^:]+):\s*(.+)$") {
                    if ($groupPrefixes -contains $Matches[1].Trim()) {
                        $field = $Matches[2].Trim()
                    }
                    else {
                        $field = $Matches[1].Trim()
                    }
                }
                $field = $field.TrimEnd(":")
                [void] $fields.Add($field)
            }
        }

        return @($fields)
    }

    $checks = @(
        @{
            Name = "hard-isolation evidence"
            Paths = @("docs/hard-isolation-evidence.template.md", "docs/templates/agents/hard-isolation-evidence.template.md")
            Markers = Get-RequiredFields "hard_isolation_evidence" "runtime_multi_agent_validation"
        },
        @{
            Name = "runtime multi-agent validation"
            Paths = @("docs/runtime-multi-agent-validation.template.md", "docs/templates/agents/runtime-multi-agent-validation.template.md")
            Markers = Get-RequiredFields "runtime_multi_agent_validation" "memory_entry"
        }
    )

    foreach ($check in $checks) {
        foreach ($path in $check.Paths) {
            $content = Get-Content -LiteralPath (Get-RepoPath $path) -Raw
            foreach ($marker in $check.Markers) {
                if (-not $content.Contains($marker)) {
                    Add-Failure ("{0} template is missing schema marker in {1}: {2}" -f $check.Name, $path, $marker)
                }
            }

            foreach ($field in Get-TemplateEvidenceFields -Path $path) {
                if ($check.Markers -notcontains $field) {
                    Add-Failure ("{0} schema is missing template field from {1}: {2}" -f $check.Name, $path, $field)
                }
            }
        }
    }

    if ($Failures.Count -eq $startFailureCount) {
        Add-Pass "Evidence template schema coverage checks passed."
    }
}

function Test-CIWorkflowStability {
    $startFailureCount = $Failures.Count
    $path = ".github/workflows/checkpoint.yml"
    $content = Get-Content -LiteralPath (Get-RepoPath $path) -Raw

    if ($content -match "runs-on:\s*windows-latest") {
        Add-Failure "Checkpoint workflow must pin a Windows runner instead of using windows-latest."
    }
    if ($content -notmatch "runs-on:\s*windows-2025-vs2026") {
        Add-Failure "Checkpoint workflow is missing the pinned windows-2025-vs2026 runner."
    }
    if ($content -match "validate\.ps1\s+-Full") {
        Add-Failure "Checkpoint workflow must use the default fast validation gate, not -Full."
    }
    if ($content -notmatch "run:\s*\.\\scripts\\validate\.ps1\s*(\r?\n|$)") {
        Add-Failure "Checkpoint workflow is missing the default validate.ps1 command."
    }
    if ($content -match "git\s+diff\s+--check") {
        Add-Failure "Checkpoint workflow must not duplicate git diff --check; full audits run that gate in scripts/validate.ps1 -Full."
    }

    if ($Failures.Count -eq $startFailureCount) {
        Add-Pass "CI workflow stability checks passed."
    }
}

function Test-ReadinessLadderEvidence {
    $startFailureCount = $Failures.Count
    $checks = @(
        @{
            Level = "P0"
            Evidence = @(
                @("docs/agents/version.yaml", "P0:"),
                @("scripts/validate.ps1", "Test-SchemaContracts"),
                @("scripts/validate.ps1", "Test-RuntimeBoundaries"),
                @("scripts/validate.ps1", "forbidden local repair")
            )
        },
        @{
            Level = "P1"
            Evidence = @(
                @("docs/agents/version.yaml", "P1:"),
                @("scripts/deploy-agents-workflow.ps1", "DryRun"),
                @("scripts/deploy-agents-workflow.ps1", "Get-TargetLayout"),
                @("scripts/deploy-agents-workflow.ps1", "Refusing to write into the provider/source repo"),
                @("scripts/deploy-agents-workflow.ps1", "requires -Upgrade"),
                @("scripts/deploy-agents-workflow.ps1", "Test-DeployPathAllowed"),
                @("scripts/deploy-agents-workflow.ps1", "Test-DeployedFileSet")
            )
        },
        @{
            Level = "P2"
            Evidence = @(
                @("docs/agents/version.yaml", "P2:"),
                @("docs/agents/version.yaml", "v1_preservation"),
                @("scripts/validate.ps1", "Test-TemplateSourceNeutrality"),
                @("scripts/validate.ps1", "Test-ExactPairs"),
                @("scripts/validate.ps1", "Test-TemplateCoverage")
            )
        },
        @{
            Level = "P3"
            Evidence = @(
                @("docs/agents/version.yaml", "P3:"),
                @("docs/agents/deploy.yaml", "deployment_worker"),
                @("docs/agents/workflows.yaml", "ownership:"),
                @("docs/agents/workflows.yaml", "ledger_missing_or_cleared"),
                @("docs/agents/workflows.yaml", "before:"),
                @("docs/agents/workflows.yaml", "during:"),
                @("docs/agents/workflows.yaml", "after:"),
                @("scripts/validate.ps1", "Test-MultiAgentWorkflowIntegrity"),
                @("scripts/validate.ps1", "Test-AgentLedgerCompatibility")
            )
        },
        @{
            Level = "P4"
            Evidence = @(
                @("docs/agents/version.yaml", "P4:"),
                @("docs/agents/verify.yaml", "release_deploy_push_audit"),
                @("docs/agents/verify.yaml", "runtime_multi_agent"),
                @("docs/agents/verify.yaml", "hard_isolation"),
                @("scripts/validate.ps1", "Test-SizeGates"),
                @("scripts/validate.ps1", "Test-EvidenceTemplateSchemaCoverage"),
                @("scripts/validate.ps1", "Test-CIWorkflowStability"),
                @("scripts/validate.ps1", "Full release audit gates passed")
            )
        },
        @{
            Level = "P5"
            Evidence = @(
                @("docs/agents/version.yaml", "P5:"),
                @("docs/agents/version.yaml", "compatibility_rule"),
                @("docs/agents/version.yaml", "rollback"),
                @("docs/agents/deploy.yaml", "target-owned state preserved"),
                @("docs/agents/workflows.yaml", "compact_output"),
                @("scripts/validate.ps1", "Test-SizeGates"),
                @("scripts/deploy-agents-workflow.ps1", "Update-TargetStateClassification"),
                @("scripts/deploy-agents-workflow.ps1", "Protected dirty/local target state observed"),
                @("scripts/deploy-agents-workflow.ps1", "Target-owned legacy Agents files outside deployed file set")
            )
        }
    )

    foreach ($check in $checks) {
        foreach ($item in $check.Evidence) {
            $path = $item[0]
            $marker = $item[1]
            $fullPath = Get-RepoPath $path
            if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) {
                Add-Failure ("{0} readiness evidence file is missing: {1}" -f $check.Level, $path)
                continue
            }

            $content = Get-Content -LiteralPath $fullPath -Raw
            if (-not $content.Contains($marker)) {
                Add-Failure ("{0} readiness evidence marker is missing in {1}: {2}" -f $check.Level, $path, $marker)
            }
        }
    }

    if ($Failures.Count -eq $startFailureCount) {
        Add-Pass "P0-P5 readiness evidence checks passed."
    }
}

function Test-SkillMetadata {
    $startFailureCount = $Failures.Count
    $skillFiles = @(
        ".agents/skills/project-isolation-workflow/SKILL.md",
        "docs/templates/agents/skills/project-isolation-workflow/SKILL.md"
    )
    foreach ($path in $skillFiles) {
        $fullPath = Get-RepoPath $path
        $head = Get-Content -LiteralPath $fullPath -TotalCount 10
        if ($head[0] -ne "---") {
            Add-Failure ("Project skill is missing YAML front matter: {0}" -f $path)
        }
        if (-not ($head | Where-Object { $_ -match "^name:\s+.+" })) {
            Add-Failure ("Project skill metadata is missing name: {0}" -f $path)
        }
        if (-not ($head | Where-Object { $_ -match "^description:\s+.+" })) {
            Add-Failure ("Project skill metadata is missing description: {0}" -f $path)
        }
    }

    foreach ($path in @(".agents/skills/project-isolation-workflow/agents/openai.yaml", "docs/templates/agents/skills/project-isolation-workflow/agents/openai.yaml")) {
        $content = Get-Content -LiteralPath (Get-RepoPath $path)
        if (-not ($content | Where-Object { $_ -match "^\s*default_prompt:" })) {
            Add-Failure ("Agent skill metadata is missing default_prompt: {0}" -f $path)
        }
    }

    if ($Failures.Count -eq $startFailureCount) {
        Add-Pass "Skill metadata checks passed."
    }
}

function Test-SizeGates {
    $startFailureCount = $Failures.Count
    $agentsSize = (Get-Item -LiteralPath (Get-RepoPath "AGENTS.md")).Length
    if ($agentsSize -gt 10240) {
        Add-Failure ("AGENTS.md exceeds 10240 bytes: {0}" -f $agentsSize)
    }

    $skillSize = (Get-Item -LiteralPath (Get-RepoPath ".agents/skills/project-isolation-workflow/SKILL.md")).Length
    if ($skillSize -gt 10240) {
        Add-Failure ("Project skill exceeds 10240 bytes: {0}" -f $skillSize)
    }

    $total = 0
    foreach ($path in Get-IntendedRepoFiles) {
        $fullPath = Get-RepoPath $path
        if (Test-Path -LiteralPath $fullPath -PathType Leaf) {
            $total += (Get-Item -LiteralPath $fullPath).Length
        }
    }
    $limit = 384 * 1024
    if ($total -gt $limit) {
        Add-Failure ("Tracked/intended repo size exceeds 384 KiB: {0} bytes" -f $total)
    }

    if ($Failures.Count -eq $startFailureCount) {
        Add-Pass ("Size gates passed: AGENTS.md {0} bytes; project skill {1} bytes; tracked repo {2} bytes." -f $agentsSize, $skillSize, $total)
    }
}

function Test-FullAuditGates {
    Test-GitDiffCheck
    Test-LineEndings
    Test-ExactPairs
    Test-DeployManifestIntegrity
    Test-TemplateCoverage
    Test-TemplateSourceNeutrality
    Test-SkillMetadata
    Test-DeploymentScriptSafety
    Test-DeploymentSelfTest
    Test-MultiAgentWorkflowIntegrity
    Test-AgentLedgerCompatibility
    Test-EvidenceTemplateSchemaCoverage
    Test-CIWorkflowStability
    Test-ReadinessLadderEvidence
    Test-SizeGates
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

    if ($Full) {
        Test-FullAuditGates
        if ($Failures.Count -eq 0) {
            Add-Pass "Full release audit gates passed."
        }
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
