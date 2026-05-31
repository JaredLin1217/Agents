param(
    [string] $TargetPath,

    [ValidateSet("core_bootstrap", "full_workflow", "template_provider_mode")]
    [string] $Mode = "core_bootstrap",

    [switch] $DryRun,
    [switch] $Upgrade,
    [switch] $CreateTarget,
    [switch] $SelfTest,
    [switch] $Quiet
)

$ErrorActionPreference = "Stop"

$RepoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$DeployManifestPath = Join-Path $RepoRoot "docs/agents/deploy.yaml"
$GitignoreFragmentPath = Join-Path $RepoRoot "docs/templates/agents/gitignore.fragment"
$DeployedFiles = New-Object System.Collections.Generic.List[string]
$PlannedWrites = New-Object System.Collections.Generic.List[string]
$ProtectedExisting = New-Object System.Collections.Generic.List[string]

function Test-SameDirectory {
    param(
        [string] $Left,
        [string] $Right
    )

    $leftFull = [System.IO.Path]::GetFullPath($Left).TrimEnd("\", "/")
    $rightFull = [System.IO.Path]::GetFullPath($Right).TrimEnd("\", "/")
    return [string]::Equals($leftFull, $rightFull, [System.StringComparison]::OrdinalIgnoreCase)
}

function Test-PathInsideRoot {
    param(
        [string] $Path,
        [string] $Root
    )

    $pathFull = [System.IO.Path]::GetFullPath($Path).TrimEnd("\", "/")
    $rootFull = [System.IO.Path]::GetFullPath($Root).TrimEnd("\", "/")
    return ($pathFull.Equals($rootFull, [System.StringComparison]::OrdinalIgnoreCase) -or
        $pathFull.StartsWith($rootFull + [System.IO.Path]::DirectorySeparatorChar, [System.StringComparison]::OrdinalIgnoreCase) -or
        $pathFull.StartsWith($rootFull + [System.IO.Path]::AltDirectorySeparatorChar, [System.StringComparison]::OrdinalIgnoreCase))
}

function Assert-RelativeDeployPath {
    param([string] $RelativePath)

    $normalized = Normalize-RepoPath $RelativePath
    if ([string]::IsNullOrWhiteSpace($normalized)) {
        throw "Deploy path must not be empty."
    }
    if ([System.IO.Path]::IsPathRooted($RelativePath) -or $normalized -match '(^|/)\.\.(/|$)') {
        throw "Deploy path must be a safe repo-relative path: $RelativePath"
    }
}

function Assert-InsideRoot {
    param(
        [string] $Path,
        [string] $Root,
        [string] $Label
    )

    if (-not (Test-PathInsideRoot -Path $Path -Root $Root)) {
        throw "$Label escapes its allowed root: $Path"
    }
}

function Write-Step {
    param(
        [string] $Status,
        [string] $Message
    )

    if (-not $Quiet) {
        Write-Host ("[{0}] {1}" -f $Status, $Message)
    }
}

function Normalize-RepoPath {
    param([string] $Path)
    return $Path.Replace("\", "/").Trim("/")
}

function Join-TargetPath {
    param(
        [string] $Root,
        [string] $RelativePath
    )

    Assert-RelativeDeployPath -RelativePath $RelativePath
    $parts = (Normalize-RepoPath $RelativePath).Split("/", [System.StringSplitOptions]::RemoveEmptyEntries)
    $path = $Root
    foreach ($part in $parts) {
        $path = Join-Path $path $part
    }
    Assert-InsideRoot -Path $path -Root $Root -Label "Target path"
    return $path
}

function Get-TargetRelativePath {
    param(
        [string] $ProviderPath,
        [string] $Layout
    )

    $path = Normalize-RepoPath $ProviderPath
    if ($Layout -eq "dot_agents_docs") {
        if ($path -eq "AGENTS.md") {
            return $path
        }
        if ($path -like ".agents/skills/*") {
            return $path
        }
        if ($path -like "docs/agents/*") {
            return $path -replace "^docs/agents/", ".agents/docs/agents/"
        }
        if ($path -like "docs/runbooks/*") {
            return $path -replace "^docs/runbooks/", ".agents/docs/runbooks/"
        }
        if ($path -like "docs/templates/agents/*") {
            return $path -replace "^docs/templates/agents/", ".agents/docs/templates/agents/"
        }
        if ($path -eq "docs/project-memory.md") {
            return ".agents/docs/project-memory.md"
        }
        if ($path -eq "docs/memory/index.md") {
            return ".agents/docs/memory/index.md"
        }
        if ($path -eq "docs/memory/entries/README.md") {
            return ".agents/docs/memory/entries/README.md"
        }
        if ($path -eq "docs/project-structure.md") {
            return ".agents/docs/project-structure.md"
        }
        if ($path -like "docs/*.md") {
            return $path -replace "^docs/", ".agents/docs/"
        }
    }

    return $path
}

function Rewrite-ContentForLayout {
    param(
        [string] $Content,
        [string] $Layout
    )

    if ($Layout -ne "dot_agents_docs") {
        return $Content
    }

    $rewritten = $Content
    $rewritten = $rewritten.Replace("docs/agents/", ".agents/docs/agents/")
    $rewritten = $rewritten.Replace("docs/runbooks/", ".agents/docs/runbooks/")
    $rewritten = $rewritten.Replace("docs/templates/agents/", ".agents/docs/templates/agents/")
    $rewritten = $rewritten.Replace("docs/project-memory.md", ".agents/docs/project-memory.md")
    $rewritten = $rewritten.Replace("docs/memory/index.md", ".agents/docs/memory/index.md")
    $rewritten = $rewritten.Replace("docs/memory/entries/README.md", ".agents/docs/memory/entries/README.md")
    $rewritten = $rewritten.Replace("docs/project-structure.md", ".agents/docs/project-structure.md")
    return $rewritten
}

function Get-TargetLayout {
    param([string] $Root)

    $agentsPath = Join-Path $Root "AGENTS.md"
    $rootDocsPath = Join-Path $Root "docs/agents"
    $dotAgentsDocsPath = Join-Path $Root ".agents/docs/agents"
    $dotAgentsSkillsPath = Join-Path $Root ".agents/skills"
    $hasRootDocs = Test-Path -LiteralPath $rootDocsPath -PathType Container
    $hasDotAgentsDocs = Test-Path -LiteralPath $dotAgentsDocsPath -PathType Container
    $hasDotAgentsSkills = Test-Path -LiteralPath $dotAgentsSkillsPath -PathType Container

    if (Test-Path -LiteralPath $agentsPath -PathType Leaf) {
        $agentsContent = Get-Content -LiteralPath $agentsPath -Raw
        if ($agentsContent -match "\.agents/docs/agents") {
            return "dot_agents_docs"
        }
        if ($agentsContent -match "docs/agents") {
            return "root_docs"
        }
    }

    if ($hasRootDocs -and $hasDotAgentsDocs) {
        throw "Target has both docs/agents and .agents/docs/agents without an AGENTS.md route. Resolve the layout or provide an AGENTS.md route before deployment."
    }

    if ($hasDotAgentsDocs -or $hasDotAgentsSkills) {
        return "dot_agents_docs"
    }
    if ($hasRootDocs) {
        return "root_docs"
    }

    return "root_docs"
}

function Get-ModeGroups {
    param([string] $SelectedMode)

    if ($SelectedMode -eq "core_bootstrap") {
        return @("core_bootstrap")
    }
    if ($SelectedMode -eq "full_workflow") {
        return @("core_bootstrap", "full_workflow_additions")
    }
    return @("core_bootstrap", "full_workflow_additions", "template_provider_additions")
}

function Get-DeployEntries {
    param([string[]] $Groups)

    $entries = New-Object System.Collections.Generic.List[object]
    $currentGroup = $null
    $currentFrom = $null
    $insideDeployable = $false

    foreach ($line in Get-Content -LiteralPath $DeployManifestPath) {
        if ($line -match "^deployable_by_mode:") {
            $insideDeployable = $true
            continue
        }
        if ($insideDeployable -and $line -match "^[a-zA-Z_]+:") {
            break
        }
        if (-not $insideDeployable) {
            continue
        }

        if ($line -match "^  ([a-zA-Z0-9_]+):") {
            $currentGroup = $Matches[1]
            $currentFrom = $null
            continue
        }
        if ($line -match '^\s+- from: "([^"]+)"') {
            $currentFrom = $Matches[1]
            continue
        }
        if ($line -match '^\s+to: "([^"]+)"') {
            if ($Groups -contains $currentGroup) {
                $entries.Add([pscustomobject]@{
                    Group = $currentGroup
                    From = $currentFrom
                    To = $Matches[1]
                }) | Out-Null
            }
            $currentFrom = $null
        }
    }

    if ($Groups -contains "template_provider_additions") {
        $templateFiles = Get-ChildItem -LiteralPath (Join-Path $RepoRoot "docs/templates/agents") -Recurse -File
        foreach ($file in $templateFiles) {
            $relative = Normalize-RepoPath ($file.FullName.Substring($RepoRoot.Path.Length).TrimStart("\", "/"))
            $entries.Add([pscustomobject]@{
                Group = "template_provider_additions"
                From = $relative
                To = $relative
            }) | Out-Null
        }
    }

    return $entries.ToArray()
}

function Confirm-SourceAllowed {
    param([string] $SourcePath)

    $normalized = Normalize-RepoPath $SourcePath
    Assert-RelativeDeployPath -RelativePath $normalized
    $blockedPrefixes = @(
        ".git/",
        ".agents/runtime/",
        ".codex/",
        "docs/agent-events/",
        "docs/tmp-approval-",
        "docs/hard-isolation-evidence/",
        "docs/runtime-multi-agent-validation/"
    )
    $blockedFiles = @(
        "docs/agent-status.md"
    )

    foreach ($prefix in $blockedPrefixes) {
        if ($normalized.StartsWith($prefix)) {
            throw "Blocked source path selected for deployment: $normalized"
        }
    }
    if ($blockedFiles -contains $normalized) {
        throw "Blocked source path selected for deployment: $normalized"
    }
}

function Append-GitignoreFragment {
    param(
        [string] $Root,
        [switch] $PlanOnly
    )

    $targetGitignore = Join-Path $Root ".gitignore"
    $fragment = Get-Content -LiteralPath $GitignoreFragmentPath
    $existing = @()
    if (Test-Path -LiteralPath $targetGitignore -PathType Leaf) {
        $existing = Get-Content -LiteralPath $targetGitignore
    }

    $missing = @($fragment | Where-Object { $_.Trim().Length -gt 0 -and ($existing -notcontains $_) })
    if ($missing.Count -eq 0) {
        $DeployedFiles.Add(".gitignore") | Out-Null
        return
    }

    $PlannedWrites.Add(".gitignore append/adapt") | Out-Null
    $DeployedFiles.Add(".gitignore") | Out-Null
    if ($PlanOnly) {
        return
    }

    if (-not (Test-Path -LiteralPath $targetGitignore -PathType Leaf)) {
        Set-Content -LiteralPath $targetGitignore -Value $fragment -Encoding utf8
        return
    }

    Add-Content -LiteralPath $targetGitignore -Value ""
    Add-Content -LiteralPath $targetGitignore -Value $fragment
}

function Copy-DeployEntry {
    param(
        [object] $Entry,
        [string] $Root,
        [string] $Layout,
        [switch] $PlanOnly
    )

    if ($Entry.To -like "*append/adapt*") {
        Append-GitignoreFragment -Root $Root -PlanOnly:$PlanOnly
        return
    }

    Confirm-SourceAllowed -SourcePath $Entry.From
    $sourcePath = Join-Path $RepoRoot $Entry.From
    Assert-InsideRoot -Path $sourcePath -Root $RepoRoot.Path -Label "Source path"
    if (-not (Test-Path -LiteralPath $sourcePath -PathType Leaf)) {
        throw "Deploy source is missing: $($Entry.From)"
    }

    $targetRelative = Get-TargetRelativePath -ProviderPath $Entry.To -Layout $Layout
    $targetFull = Join-TargetPath -Root $Root -RelativePath $targetRelative
    $DeployedFiles.Add($targetRelative) | Out-Null
    $PlannedWrites.Add($targetRelative) | Out-Null

    if (Test-Path -LiteralPath $targetFull -PathType Leaf) {
        $ProtectedExisting.Add($targetRelative) | Out-Null
    }

    if ($PlanOnly) {
        return
    }

    $targetDir = Split-Path -Parent $targetFull
    if (-not (Test-Path -LiteralPath $targetDir -PathType Container)) {
        New-Item -ItemType Directory -Path $targetDir | Out-Null
    }

    $content = Get-Content -LiteralPath $sourcePath -Raw
    $content = Rewrite-ContentForLayout -Content $content -Layout $Layout
    Set-Content -LiteralPath $targetFull -Value $content -NoNewline -Encoding utf8
}

function Write-DeploymentReport {
    param(
        [string] $Root,
        [string] $Layout,
        [switch] $PlanOnly
    )

    $reportRelative = if ($Layout -eq "dot_agents_docs") {
        ".agents/docs/agents-workflow-deployment.md"
    }
    else {
        "docs/agents-workflow-deployment.md"
    }
    $reportPath = Join-TargetPath -Root $Root -RelativePath $reportRelative
    $DeployedFiles.Add($reportRelative) | Out-Null
    $PlannedWrites.Add($reportRelative) | Out-Null
    $reportLines = @(
        "# Agents Workflow Deployment",
        "",
        ("Mode: {0}" -f $Mode),
        ("Upgrade: {0}" -f [bool] $Upgrade),
        ("Layout: {0}" -f $Layout),
        ("Dry run: {0}" -f [bool] $PlanOnly),
        "",
        "## Deployed File Set",
        ""
    )
    foreach ($file in ($DeployedFiles | Sort-Object -Unique)) {
        $reportLines += ("- {0}" -f $file)
    }
    $reportLines += @(
        "",
        "## Notes",
        "",
        "- Runtime, local Codex config, Git metadata, status, event, and filled evidence files are not deployed.",
        "- Target-owned legacy Agents files are reported separately and remain target-owned."
    )

    if ($PlanOnly) {
        return
    }

    $reportDir = Split-Path -Parent $reportPath
    if (-not (Test-Path -LiteralPath $reportDir -PathType Container)) {
        New-Item -ItemType Directory -Path $reportDir | Out-Null
    }
    Set-Content -LiteralPath $reportPath -Value $reportLines -Encoding utf8
}

function Reset-Directory {
    param(
        [string] $Path,
        [string] $AllowedRoot
    )

    if (Test-Path -LiteralPath $Path) {
        Assert-InsideRoot -Path $Path -Root $AllowedRoot -Label "Self-test cleanup path"
        Remove-Item -LiteralPath $Path -Recurse -Force
    }
    New-Item -ItemType Directory -Path $Path | Out-Null
}

function Assert-SelfTestFile {
    param(
        [string] $Root,
        [string] $RelativePath
    )

    $path = Join-TargetPath -Root $Root -RelativePath $RelativePath
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "Deployment self-test expected file is missing: $RelativePath"
    }
}

function Assert-NoSourceLiteral {
    param([string] $Root)

    $sourceLiterals = @(
        $RepoRoot.Path,
        (Split-Path -Leaf $RepoRoot.Path),
        "JaredLin"
    )
    $files = Get-ChildItem -LiteralPath $Root -Recurse -File |
        Where-Object { $_.Extension.ToLowerInvariant() -in @(".md", ".yaml", ".yml", ".json", ".toml", ".ps1") }

    foreach ($literal in $sourceLiterals) {
        foreach ($file in $files) {
            $match = Select-String -LiteralPath $file.FullName -Pattern $literal -SimpleMatch -Quiet -ErrorAction SilentlyContinue
            if ($match) {
                throw "Deployment self-test found source-specific literal in target file: $($file.FullName)"
            }
        }
    }
}

function Invoke-ChildDeployment {
    param([hashtable] $CommandArgs)

    try {
        & $PSCommandPath @CommandArgs
        if (-not $?) {
            throw "Child deployment command returned a failed status."
        }
    }
    catch {
        throw $_
    }
}

function Invoke-DeploymentSelfTest {
    $projectId = "jared-ai-team"
    $statusRoot = Join-Path ([System.IO.Path]::GetTempPath()) "codex-agent-status"
    $projectRoot = Join-Path $statusRoot $projectId
    $selfTestRoot = Join-Path $projectRoot "deploy-selftest"

    if (-not (Test-Path -LiteralPath $statusRoot -PathType Container)) {
        New-Item -ItemType Directory -Path $statusRoot | Out-Null
    }
    if (-not (Test-Path -LiteralPath $projectRoot -PathType Container)) {
        New-Item -ItemType Directory -Path $projectRoot | Out-Null
    }
    Assert-InsideRoot -Path $selfTestRoot -Root $projectRoot -Label "Self-test root"
    Reset-Directory -Path $selfTestRoot -AllowedRoot $projectRoot

    $rootTarget = Join-Path $selfTestRoot "root-docs"
    Invoke-ChildDeployment -CommandArgs @{ TargetPath = $rootTarget; Mode = "full_workflow"; CreateTarget = $true; Quiet = $true }
    Assert-SelfTestFile -Root $rootTarget -RelativePath "AGENTS.md"
    Assert-SelfTestFile -Root $rootTarget -RelativePath "docs/agents/workflows.yaml"
    Assert-SelfTestFile -Root $rootTarget -RelativePath "docs/agents-workflow-deployment.md"
    Assert-NoSourceLiteral -Root $rootTarget

    $dotTarget = Join-Path $selfTestRoot "dot-agents-docs"
    New-Item -ItemType Directory -Path $dotTarget | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $dotTarget ".agents/skills") -Force | Out-Null
    Set-Content -LiteralPath (Join-Path $dotTarget "AGENTS.md") -Value "Route to .agents/docs/agents." -Encoding utf8
    Invoke-ChildDeployment -CommandArgs @{ TargetPath = $dotTarget; Mode = "core_bootstrap"; Quiet = $true }
    Assert-SelfTestFile -Root $dotTarget -RelativePath "AGENTS.md"
    Assert-SelfTestFile -Root $dotTarget -RelativePath ".agents/docs/agents/workflows.yaml"
    Assert-SelfTestFile -Root $dotTarget -RelativePath ".agents/docs/agents-workflow-deployment.md"
    Assert-NoSourceLiteral -Root $dotTarget

    $sourceWriteBlocked = $false
    try {
        Invoke-ChildDeployment -CommandArgs @{ TargetPath = $RepoRoot.Path; Mode = "core_bootstrap"; Quiet = $true }
    }
    catch {
        $sourceWriteBlocked = $true
    }
    if (-not $sourceWriteBlocked) {
        throw "Deployment self-test expected provider/source write refusal."
    }

    Write-Step "PASS" "Deployment self-test completed."
}

if ($SelfTest) {
    Invoke-DeploymentSelfTest
    exit 0
}

if ([string]::IsNullOrWhiteSpace($TargetPath)) {
    throw "TargetPath is required unless -SelfTest is used."
}

$resolvedTarget = Resolve-Path -LiteralPath $TargetPath -ErrorAction SilentlyContinue
if (-not $resolvedTarget) {
    if ($DryRun) {
        throw "Target path must exist for dry-run inspection: $TargetPath"
    }
    if (-not $CreateTarget) {
        throw "Target path does not exist. Create it explicitly first or rerun with -CreateTarget after confirming the exact path: $TargetPath"
    }
    New-Item -ItemType Directory -Path $TargetPath | Out-Null
    $resolvedTarget = Resolve-Path -LiteralPath $TargetPath
}

if (-not (Test-Path -LiteralPath $resolvedTarget -PathType Container)) {
    throw "Target path is not a directory: $TargetPath"
}

$targetRoot = $resolvedTarget.Path
if ((Test-PathInsideRoot -Path $targetRoot -Root $RepoRoot.Path) -and (-not $DryRun)) {
    throw "Refusing to write into the provider/source repo or one of its child directories. Use -DryRun for provider self-checks or provide an external target path."
}

$layout = Get-TargetLayout -Root $targetRoot
$groups = Get-ModeGroups -SelectedMode $Mode
$entries = Get-DeployEntries -Groups $groups

Write-Step "INFO" ("Source repo: {0}" -f $RepoRoot)
Write-Step "INFO" ("Target repo: {0}" -f $targetRoot)
Write-Step "INFO" ("Mode: {0}" -f $Mode)
Write-Step "INFO" ("Upgrade: {0}" -f [bool] $Upgrade)
Write-Step "INFO" ("Layout: {0}" -f $layout)
Write-Step "INFO" ("Dry run: {0}" -f [bool] $DryRun)

foreach ($entry in $entries) {
    Copy-DeployEntry -Entry $entry -Root $targetRoot -Layout $layout -PlanOnly:$DryRun
}
Write-DeploymentReport -Root $targetRoot -Layout $layout -PlanOnly:$DryRun

Write-Step "INFO" "Deployed file set:"
foreach ($file in ($DeployedFiles | Sort-Object -Unique)) {
    Write-Step "FILE" $file
}

if ($ProtectedExisting.Count -gt 0) {
    Write-Step "INFO" "Existing target files that would be updated:"
    foreach ($file in ($ProtectedExisting | Sort-Object -Unique)) {
        Write-Step "EXISTING" $file
    }
}

if ($DryRun) {
    Write-Step "PASS" "Dry-run deployment plan completed without writing target files."
}
else {
    Write-Step "PASS" "Agents workflow deployment completed."
}
