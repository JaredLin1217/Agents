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
    $casePath = Get-RepoPath "tests/agents-governance-fixtures/schema-contracts/cases.json"
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

function Test-GitDiffCheck {
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
}

function Get-IntendedRepoFiles {
    $files = @(
        & git -C $RepoRoot ls-files
        & git -C $RepoRoot ls-files --others --exclude-standard
    ) | Where-Object { $_ } | Sort-Object -Unique

    return @($files)
}

function Test-ExactPairs {
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
}

function Test-TemplateCoverage {
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
}

function Test-DeployManifestIntegrity {
    $deployPaths = @("docs/agents/deploy.yaml", "docs/templates/agents/agents/deploy.yaml")
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
        foreach ($line in $content) {
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

        foreach ($required in @(".agents/runtime/", ".codex/config.toml", ".codex/environments/environment.toml", ".git/")) {
            if (-not ($content | Where-Object { $_ -match [regex]::Escape($required) })) {
                Add-Failure ("Deploy blocklist is missing required path in {0}: {1}" -f $path, $required)
            }
        }
    }
}

function Test-SkillMetadata {
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
}

function Test-SizeGates {
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
    $limit = 256 * 1024
    if ($total -gt $limit) {
        Add-Failure ("Tracked/intended repo size exceeds 256 KiB: {0} bytes" -f $total)
    }
}

function Test-FullAuditGates {
    Test-GitDiffCheck
    Test-ExactPairs
    Test-DeployManifestIntegrity
    Test-TemplateCoverage
    Test-SkillMetadata
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
