# Banc de test du skill /extraire-taches.
# Lance un cas avec `claude -p` depuis un dossier neutre (le modèle ne voit ni la spec ni le skill),
# écriture Airtable interdite sauf -AllowWrite.
param(
    [Parameter(Mandatory)][string]$Case,
    [ValidateSet('with', 'without', 'raw', 'installed')][string]$Arm = 'with',
    [string]$Resume,
    [switch]$AllowWrite
)
$ErrorActionPreference = 'Stop'
$OutputEncoding = [System.Text.UTF8Encoding]::new($false)
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false)

$testsDir = $PSScriptRoot
$pluginDir = Split-Path -Parent $testsDir
$caseText = Get-Content (Join-Path $testsDir "cases\$Case.md") -Raw -Encoding UTF8

function Get-Section([string]$Name) {
    $m = [regex]::Match($caseText, "(?ms)^## $Name\s*\r?\n(.*?)(?=^## |\z)")
    if ($m.Success) { return $m.Groups[1].Value.Trim() }
    return $null
}

if ($Resume) {
    $prompt = Get-Section 'Réponse simulée'
    if (-not $prompt) { throw "Le cas $Case n'a pas de section '## Réponse simulée'." }
} else {
    $entree = (Get-Section 'Entrée').Replace('{{TESTS}}', $testsDir)
    switch ($Arm) {
        'without' { $prompt = "Extrais les tâches à réaliser de ce texte et crée-les dans la base Airtable « Team & Project Management V3 », table Task.`n`n$entree" }
        'raw'     { $prompt = $entree }
        default   { $prompt = "/extraire-taches $entree" }
    }
}

$readTools = @(
    'Read',
    'mcp__claude_ai_Airtable__search_bases',
    'mcp__claude_ai_Airtable__list_bases',
    'mcp__claude_ai_Airtable__list_tables_for_base',
    'mcp__claude_ai_Airtable__get_table_schema',
    'mcp__claude_ai_Airtable__list_records_for_table',
    'mcp__claude_ai_Airtable__search_records'
)
$writeTools = @(
    'mcp__claude_ai_Airtable__create_records_for_table',
    'mcp__claude_ai_Airtable__update_records_for_table',
    'mcp__claude_ai_Airtable__delete_records_for_table'
)

$cliArgs = @('-p', '--output-format', 'json',
    '--settings', (Join-Path $testsDir 'harness-settings.json'),
    '--max-turns', '40', '--max-budget-usd', '3')
if ($AllowWrite) {
    $cliArgs += @('--allowedTools') + $readTools + @('mcp__claude_ai_Airtable__create_records_for_table')
    $cliArgs += @('--disallowedTools', 'mcp__claude_ai_Hub_mcp1')
} else {
    $cliArgs += @('--allowedTools') + $readTools
    $cliArgs += @('--disallowedTools') + $writeTools + @('mcp__claude_ai_Hub_mcp1')
}
if ($Arm -eq 'with') { $cliArgs += @('--plugin-dir', $pluginDir) }
if ($Resume) { $cliArgs += @('--resume', $Resume) }

$work = Join-Path $env:TEMP 'extraire-taches-tests'
New-Item -ItemType Directory -Force $work | Out-Null
Push-Location $work
try { $raw = ($prompt | claude @cliArgs) -join "`n" } finally { Pop-Location }

$res = $raw | ConvertFrom-Json
$resultsDir = Join-Path $testsDir 'results'
New-Item -ItemType Directory -Force $resultsDir | Out-Null
$suffix = if ($Resume) { '-tour2' } else { '' }
$out = Join-Path $resultsDir ("{0}-{1}{2}-{3}.json" -f $Case, $Arm, $suffix, (Get-Date -Format 'yyyyMMdd-HHmmss'))
$raw | Set-Content -Path $out -Encoding UTF8

"session_id : $($res.session_id)"
"coût (USD) : $($res.total_cost_usd)"
"outils refusés : $((@($res.permission_denials) | ForEach-Object { $_.tool_name }) -join ', ')"
"sortie : $out"
'----'
$res.result
