function Test-FoundationCreationIntegrity {
$startFailureCount = $Failures.Count
$requiredFiles = @(
"docs/agents/openai-foundations.yaml",
"docs/templates/agents/agents/openai-foundations.yaml",
"schemas/agents-openai-foundations.schema.json"
)
$allRequiredFilesExist = $true
foreach ($path in $requiredFiles) {
if (-not (Test-Path -LiteralPath (Get-RepoPath $path) -PathType Leaf)) {
Add-Failure ("Foundation creation required file is missing: {0}" -f $path)
$allRequiredFilesExist = $false
}
}
if (-not $allRequiredFilesExist) {
return
}
$canonicalFile = Get-Item -LiteralPath (Get-RepoPath "docs/agents/openai-foundations.yaml")
$templateFile = Get-Item -LiteralPath (Get-RepoPath "docs/templates/agents/agents/openai-foundations.yaml")
if ((Get-FileHash -LiteralPath $canonicalFile.FullName -Algorithm SHA256).Hash -ne (Get-FileHash -LiteralPath $templateFile.FullName -Algorithm SHA256).Hash) {
Add-Failure "Foundation creation canonical and template mirror must be identical."
}
$foundationText = Get-Content -LiteralPath $canonicalFile.FullName -Raw
$aiRuntimeText = Get-Content -LiteralPath (Get-RepoPath "docs/agents/ai-runtime.yaml") -Raw
$schemasText = Get-Content -LiteralPath (Get-RepoPath "docs/agents/schemas.yaml") -Raw
$verifyText = Get-Content -LiteralPath (Get-RepoPath "docs/agents/verify.yaml") -Raw
$deployText = Get-Content -LiteralPath (Get-RepoPath "docs/agents/deploy.yaml") -Raw
foreach ($marker in @(
"official_docs_first",
"structured_outputs",
"conversation_state",
"agents_sdk",
"codex_skills",
"subagents",
"prompt_caching",
"predicted_outputs",
"evaluations",
"evaluation"
)) {
if (-not $foundationText.Contains($marker)) {
Add-Failure ("Foundation creation canonical is missing marker: {0}" -f $marker)
}
foreach ($marker in @("source_matrix:", "checked:", "capability:", "url:", "boundary:", "drift_risk:", "2026-06-23")) {
if (-not $foundationText.Contains($marker)) {
Add-Failure ("Foundation source matrix is missing field or value: {0}" -f $marker)
}
}
$sourceMatrix = @(
@("structured_outputs", "Structured Outputs", "https://developers.openai.com/api/docs/guides/structured-outputs"),
@("conversation_state", "conversation state", "https://developers.openai.com/api/docs/guides/conversation-state"),
@("agents_sdk", "Agents SDK", "https://openai.github.io/openai-agents-python/"),
@("codex_skills", "Codex skills", "https://developers.openai.com/codex/skills"),
@("subagents", "subagents", "https://developers.openai.com/codex/subagents"),
@("prompt_caching", "prompt caching", "https://developers.openai.com/api/docs/guides/prompt-caching"),
@("predicted_outputs", "predicted outputs", "https://developers.openai.com/api/docs/guides/predicted-outputs"),
@("evaluations", "evaluations", "https://developers.openai.com/api/docs/guides/evals")
)
foreach ($source in $sourceMatrix) {
foreach ($marker in $source) {
if (-not $foundationText.Contains($marker)) {
Add-Failure ("Foundation source matrix is missing marker: {0}" -f $marker)
}
}
}
}
foreach ($marker in @("foundation_creation", "docs/agents/openai-foundations.yaml")) {
if (-not $aiRuntimeText.Contains($marker)) {
Add-Failure ("Foundation creation route is missing marker: {0}" -f $marker)
}
}
if ($aiRuntimeText -notmatch 'foundation_creation:\s*\{\s*f:\s*\[[^\]]*"docs/agents/openai-foundations\.yaml"[^\]]*"docs/agents/schemas\.yaml"[^\]]*"docs/agents/verify\.yaml"[^\]]*\]') {
Add-Failure "Foundation creation route must load openai-foundations, schemas, and verify."
}
foreach ($marker in @("foundation_creation", "Structured Outputs", "state owner")) {
if (-not $schemasText.Contains($marker)) {
Add-Failure ("Foundation creation schema registry is missing marker: {0}" -f $marker)
}
}
foreach ($marker in @("foundation_creation", "foundation_creation_integrity")) {
if (-not $verifyText.Contains($marker)) {
Add-Failure ("Foundation creation verify profile is missing marker: {0}" -f $marker)
}
}
if (-not $deployText.Contains("docs/templates/agents/agents/openai-foundations.yaml")) {
Add-Failure "Foundation creation deploy source is missing."
}
if ($Failures.Count -eq $startFailureCount) {
Add-Pass "Foundation creation integrity checks passed."
}
}
