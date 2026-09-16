# Banc de test du skill /extraire-taches.
# Lance un cas avec `claude -p` depuis un dossier neutre (le modèle ne voit ni la spec ni le skill).
#
# Écriture Airtable. Les réglages du banc (`tests/harness-settings.json`) contiennent une liste
# `permissions.deny`, qui l'emporte sur toute règle `allow` des réglages du compte (par ex.
# `mcp__claude_ai_Airtable__*`). Sont refusés :
#   - serveur mcp__claude_ai_Airtable, les 21 outils qui écrivent ou modifient :
#     create_automation, create_base, create_field, create_interface, create_page,
#     create_record_comment, create_records_for_table, create_table, delete_automation,
#     delete_interface, delete_page, delete_records_for_table, delete_table, publish_interface,
#     revert_action, submit_form, test_automation_webhook_trigger, update_automation,
#     update_field, update_records_for_table, update_table ;
#   - les serveurs mcp__claude_ai_homer-airtable, mcp__claude_ai_homer_airtable (connecteur
#     « claude.ai homer airtable ») et mcp__claude_ai_Hub_mcp1 en entier (ils exposent les
#     mêmes bases par un autre connecteur).
# Les 25 outils de lecture du serveur Airtable (list_*, get_*, search_*, analyze_table,
# describe_*, fetch_automation_input_data, ping) restent ouverts.
# Vérifié le 2026-09-16 (Claude Code 2.1.217) sur la liste `tools` de l'événement `init`
# (`--output-format stream-json --verbose`, avec MCP_CONNECTION_NONBLOCKING=false) : les
# outils refusés disparaissent de la liste.
#
# Avec -AllowWrite, le banc bascule sur `tests/harness-settings-write.json` : même liste moins
# create_records_for_table. Seule la création d'enregistrements devient possible ; update_records,
# delete_records et tout le reste restent refusés.
#
# `--disallowedTools` double cette règle mais ne la remplace pas : seule la liste `deny` des
# réglages neutralise l'autorisation globale du compte.
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
    $entree = Get-Section 'Entrée'
    if (-not $entree) { throw "Le cas $Case n'a pas de section '## Entrée'." }
    $entree = $entree.Replace('{{TESTS}}', $testsDir)
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

$settingsFile = if ($AllowWrite) { 'harness-settings-write.json' } else { 'harness-settings.json' }
$cliArgs = @('-p', '--output-format', 'json',
    '--settings', (Join-Path $testsDir $settingsFile),
    '--max-turns', '40', '--max-budget-usd', '3')
if ($AllowWrite) {
    $cliArgs += @('--allowedTools') + $readTools + @('mcp__claude_ai_Airtable__create_records_for_table')
    $cliArgs += @('--disallowedTools',
        'mcp__claude_ai_Airtable__update_records_for_table',
        'mcp__claude_ai_Airtable__delete_records_for_table',
        'mcp__claude_ai_Hub_mcp1')
} else {
    $cliArgs += @('--allowedTools') + $readTools
    $cliArgs += @('--disallowedTools') + $writeTools + @('mcp__claude_ai_Hub_mcp1')
}
if ($Arm -eq 'with') { $cliArgs += @('--plugin-dir', $pluginDir) }
if ($Resume) { $cliArgs += @('--resume', $Resume) }

# Un dossier de travail neuf par conversation : Claude Code range sessions et mémoire
# automatique par dossier ; un dossier partagé ferait passer la mémoire d'un cas à l'autre.
$resultsDir = Join-Path $testsDir 'results'
$sessionsDir = Join-Path $resultsDir 'sessions'
New-Item -ItemType Directory -Force $sessionsDir | Out-Null
if ($Resume) {
    $mapFile = Join-Path $sessionsDir "$Resume.txt"
    if (-not (Test-Path $mapFile)) { throw "Session inconnue : $Resume (aucun dossier de travail enregistré)." }
    $work = (Get-Content $mapFile -Raw -Encoding UTF8).Trim()
} else {
    $work = Join-Path $env:TEMP ("extraire-taches-tests\{0}-{1}-{2}" -f $Case, $Arm, (Get-Date -Format 'yyyyMMdd-HHmmss'))
}
New-Item -ItemType Directory -Force $work | Out-Null
Push-Location $work
try { $raw = ($prompt | claude @cliArgs) -join "`n" } finally { Pop-Location }

# La sortie brute est enregistrée avant toute analyse : si ce n'est pas du JSON (erreur
# d'authentification, message du CLI), elle reste consultable au lieu d'être perdue.
$suffix = if ($Resume) { '-tour2' } else { '' }
$out = Join-Path $resultsDir ("{0}-{1}{2}-{3}.json" -f $Case, $Arm, $suffix, (Get-Date -Format 'yyyyMMdd-HHmmss'))
$raw | Set-Content -Path $out -Encoding UTF8

$res = $null
try { $res = $raw | ConvertFrom-Json } catch { $res = $null }
if ($null -eq $res) {
    "sortie brute (JSON illisible) : $out"
    '----'
    $raw
    exit 1
}

if (-not $Resume) {
    Set-Content -Path (Join-Path $sessionsDir "$($res.session_id).txt") -Value $work -Encoding UTF8
}

"session_id : $($res.session_id)"
"subtype : $($res.subtype)"
"is_error : $($res.is_error)"
"coût (USD) : $($res.total_cost_usd)"
"outils refusés : $((@($res.permission_denials) | ForEach-Object { $_.tool_name }) -join ', ')"
"sortie : $out"
'----'
$res.result
