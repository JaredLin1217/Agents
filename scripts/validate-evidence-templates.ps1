function Get-RequiredEvidenceFields {
param(
[string] $Section,
[string] $NextSection
)
$schemaContent = Get-Content -LiteralPath (Get-RepoPath "docs/agents/schemas.yaml") -Raw
$sectionStart = $schemaContent.IndexOf(("{0}:" -f $Section))
$sectionEnd = $schemaContent.IndexOf(("{0}:" -f $NextSection), $sectionStart + 1)
if ($sectionStart -lt 0 -or $sectionEnd -lt 0) {
Add-Failure ("Schema section boundary is missing: {0} -> {1}" -f $Section, $NextSection)
return @()
}
$sectionText = $schemaContent.Substring($sectionStart, $sectionEnd - $sectionStart)
$bulletFields = @([regex]::Matches($sectionText, '^\s*-\s+"([^"]+)"', [System.Text.RegularExpressions.RegexOptions]::Multiline) |
ForEach-Object { $_.Groups[1].Value })
if ($bulletFields.Count -gt 0) {
return $bulletFields
}
$compactFields = [regex]::Match($sectionText, 'required_fields:\s*\[(.*?)\]', [System.Text.RegularExpressions.RegexOptions]::Singleline)
if ($compactFields.Success) {
return @([regex]::Matches($compactFields.Groups[1].Value, '"([^"]+)"') | ForEach-Object { $_.Groups[1].Value })
}
return @()
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
"Batch proof",
"Boundary",
"Work result",
"Events",
"Close/cleanup",
"Dry run",
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

function Test-EvidenceTemplateSchemaCoverage {
$startFailureCount = $Failures.Count
$checks = @(
@{
Name = "hard-isolation evidence"
Paths = @("docs/hard-isolation-evidence.template.md", "docs/templates/agents/hard-isolation-evidence.template.md")
Markers = Get-RequiredEvidenceFields "hard_isolation_evidence" "runtime_multi_agent_validation"
},
@{
Name = "runtime multi-agent validation"
Paths = @("docs/runtime-multi-agent-validation.template.md", "docs/templates/agents/runtime-multi-agent-validation.template.md")
Markers = Get-RequiredEvidenceFields "runtime_multi_agent_validation" "runtime_dry_run_evidence"
},
@{
Name = "runtime dry-run evidence"
Paths = @("docs/runtime-dry-run-evidence.template.md", "docs/templates/agents/runtime-dry-run-evidence.template.md")
Markers = Get-RequiredEvidenceFields "runtime_dry_run_evidence" "memory_entry"
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
