# Plan d'implémentation — Skill `/extraire-taches`

> **Pour les agents d'exécution :** SOUS-SKILL REQUIS : superpowers:subagent-driven-development (recommandé) ou superpowers:executing-plans, tâche par tâche. Les étapes utilisent des cases à cocher (`- [ ]`) pour le suivi.

**Objectif :** livrer un plugin Claude Code `extraire-taches` (dépôt privé `novekai/extraire-taches`) dont le skill `/extraire-taches` transforme un texte en tâches Airtable, après questions et validation.

**Architecture :** un plugin à skill unique : `SKILL.md` à la racine (commande sans préfixe), manifeste `plugin.json`, place de marché `marketplace.json` pointant sur le dépôt lui-même. Les tests passent par un banc PowerShell qui lance `claude -p` sans interface, avec ou sans le plugin, écriture Airtable interdite.

**Technologies :** Claude Code 2.1.217, skills (SKILL.md), connecteur claude.ai Airtable (`mcp__claude_ai_Airtable__*`), PowerShell 5.1, git/gh.

**Spec :** `docs/specs/2026-09-15-extraire-taches-design.md`

## Contraintes globales

- Langue : tout le contenu destiné à l'utilisateur est en français.
- Destination par défaut : base `appeQ2eExbWynIgDK` (Team & Project Management V3), table `tblttmFAIQZK6zrXo` (Task).
- Six champs seulement : Task title `fldydXgRrUk29WfRp`, Description `fldteZklRjdB9eiR5`, Status `fldJYU13yvGqIWnvI`, Team List `fldVg3Jvi1Fcs7VyW`, Projet `fldHMSLQ4d8tur42H`, Start Date `fldcip8GeFJeMUaiQ`.
- Aucune écriture Airtable sans validation explicite de l'aperçu. Pendant les tests, les outils d'écriture sont interdits par le banc.
- `SKILL.md` à la racine avec `name: extraire-taches` → commande `/extraire-taches`.
- `userConfig` : la substitution `${user_config.…}` n'est pas appliquée tant que la valeur n'est pas saisie (vérifié le 15/09/2026). Le skill doit donc retomber sur la destination par défaut écrite dans `SKILL.md`.
- `claude plugin eval` est en accès anticipé : non utilisable. Banc maison `tests/run-case.ps1`.
- Push GitHub avec le compte `novekai` : `git -c credential.helper= -c "credential.helper=!gh auth git-credential" push`.

## Structure des fichiers

| Fichier | Rôle |
|---|---|
| `.claude-plugin/plugin.json` | Identité du plugin, réglages d'installation |
| `.claude-plugin/marketplace.json` | Place de marché `novekai` → installation depuis GitHub |
| `SKILL.md` | Le skill : déroulé, règles, destination par défaut |
| `README.md` | Prérequis, installation, utilisation |
| `.gitignore` | Exclut `tests/results/` |
| `tests/harness-settings.json` | Désactive les autres plugins pendant les tests |
| `tests/run-case.ps1` | Banc : lance un cas, enregistre la sortie JSON |
| `tests/cases/T0.md` … `T7.md` | Cas de test : entrée, réponse simulée, attendus |
| `tests/fixtures/notes-T7.md` | Fichier d'entrée du cas T7 |
| `tests/results.md` | Journal : défauts de la baseline, verdicts avec skill |

---

### Tâche 1 : Squelette du plugin et banc de test

**Fichiers :**
- Créer : `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`, `.gitignore`, `tests/harness-settings.json`, `tests/run-case.ps1`, `tests/cases/T0.md`

**Interfaces :**
- Produit : `tests/run-case.ps1 -Case <Tn> [-Arm with|without|raw|installed] [-Resume <session_id>] [-AllowWrite]`. Affiche `session_id`, coût, outils refusés, puis la réponse. Enregistre la sortie JSON dans `tests/results/<Tn>-<arm>[-tour2]-<horodatage>.json`.
- Format d'un cas : sections `## Entrée`, `## Réponse simulée` (facultative, utilisée avec `-Resume`), `## Attendu`.

- [ ] **Étape 1 : écrire `.claude-plugin/plugin.json`**

```json
{
  "name": "extraire-taches",
  "version": "0.1.0",
  "description": "Transforme un texte (compte-rendu, liste de points, brief) en tâches structurées et les crée dans Airtable après validation.",
  "author": { "name": "NovekAI", "email": "espoir@novekai.agency" },
  "homepage": "https://github.com/novekai/extraire-taches",
  "repository": "https://github.com/novekai/extraire-taches",
  "license": "UNLICENSED",
  "keywords": ["airtable", "tâches", "compte-rendu", "gestion de projet"],
  "userConfig": {
    "airtable_base_id": {
      "type": "string",
      "title": "ID de la base Airtable",
      "description": "Base où créer les tâches (commence par app). Vide = Team & Project Management V3.",
      "required": false
    },
    "airtable_table_id": {
      "type": "string",
      "title": "ID de la table Airtable",
      "description": "Table où créer les tâches (commence par tbl). Vide = Task.",
      "required": false
    }
  }
}
```

- [ ] **Étape 2 : écrire `.claude-plugin/marketplace.json`**

```json
{
  "name": "novekai",
  "description": "Plugins Claude Code de NovekAI",
  "owner": { "name": "NovekAI", "email": "espoir@novekai.agency" },
  "plugins": [
    {
      "name": "extraire-taches",
      "description": "Transforme un texte en tâches structurées et les crée dans Airtable après validation.",
      "version": "0.1.0",
      "source": "./"
    }
  ]
}
```

- [ ] **Étape 3 : écrire `.gitignore`**

```
tests/results/
```

- [ ] **Étape 4 : écrire `tests/harness-settings.json`**

```json
{
  "enabledPlugins": {
    "superpowers@claude-plugins-official": false
  }
}
```

- [ ] **Étape 5 : écrire `tests/run-case.ps1`**

```powershell
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
```

- [ ] **Étape 6 : écrire `tests/cases/T0.md`**

```markdown
# T0 — Vérification du banc

## Entrée
Réponds uniquement : OK

## Attendu
- La réponse est « OK ».
```

- [ ] **Étape 7 : valider les manifestes**

Exécuter :
```
claude plugin validate --strict .\.claude-plugin\plugin.json
claude plugin validate --strict .
```
Attendu : `Validation passed` pour les deux. (Le second peut signaler l'absence de `SKILL.md` ; l'accepter à ce stade, il est ajouté en tâche 3.)

- [ ] **Étape 8 : vérifier le banc**

Exécuter : `.\tests\run-case.ps1 -Case T0 -Arm raw`
Attendu : un `session_id`, `outils refusés :` vide, réponse `OK`, un fichier JSON dans `tests/results/`.

- [ ] **Étape 9 : commit**

```
git add .claude-plugin .gitignore tests/harness-settings.json tests/run-case.ps1 tests/cases/T0.md
git commit -m "chore: squelette du plugin et banc de test"
```

---

### Tâche 2 : Cas de test et baseline sans skill (RED)

**Fichiers :**
- Créer : `tests/cases/T1.md` … `tests/cases/T6.md`, `tests/results.md`

**Interfaces :**
- Consomme : `tests/run-case.ps1` (tâche 1).
- Produit : six cas au format de la tâche 1 ; `tests/results.md` avec une section « Baseline » listant les défauts observés, citations exactes à l'appui.

Repères pour juger (données réelles au 15/09/2026) :
- Le 15/09/2026 est un mardi : « demain » = 16/09/2026, « lundi » = 21/09/2026.
- Personnes actives citées : Aurel, Hugues, Martial, Modeste. Tous les projets « Eureka/Eurêka » (Site web Eurêka, Application web Eureka, Blog Eurekâ) sont `Annulé`.
- Tâche existante (doublon attendu en T4) : « Support Client : Analyse du message envoyé par Salma sur les améliorations à apporter », projet Loup X Lotchi, Aurel, To Do.

- [ ] **Étape 1 : écrire `tests/cases/T1.md`**

```markdown
# T1 — Liste claire

## Entrée
Points à faire suite au point d'équipe du 15/09/2026 :
- Aurel : analyser le retour de Salma sur les améliorations du support client Lotchi (projet Loup X Lotchi), démarrage le 16/09/2026. Il faut lire son message, lister les améliorations demandées et les classer par priorité.
- Hugues : préparer la démo IronClassic pour le client, démarrage le 17/09/2026. Étapes : mettre à jour les données de test, enregistrer une vidéo de 3 minutes, l'envoyer à Espoir.

## Attendu
- Deux tâches exactement.
- Tâche Aurel : projet Loup X Lotchi, début 16/09/2026, 3 étapes reprenant le texte (lire, lister, classer).
- Tâche Hugues : projet IronClassic, début 17/09/2026, 3 étapes reprenant le texte (données de test, vidéo de 3 minutes, envoi à Espoir).
- Titres : verbe à l'infinitif, 10 mots max, sans prénom ni date.
- Aucune étape, aucun outil ni chiffre absent du texte.
- La tâche Aurel peut être signalée comme proche de la tâche existante « Support Client : Analyse du message envoyé par Salma… » avec la question « Créer quand même ? ».
- Aperçu au format tableau + étapes + source, puis demande de validation. Aucune tentative d'écriture.
```

- [ ] **Étape 2 : écrire `tests/cases/T2.md`**

```markdown
# T2 — Texte flou

## Entrée
Il faudrait que quelqu'un reprenne le site Eureka, les retours du client sont arrivés. Martial doit aussi voir pour le SEO. Et penser à relancer le client pour le paiement.

## Réponse simulée
1. Site Eureka : c'est Martial, projet Site web Eurêka même s'il est annulé, début le 22/09/2026. Il doit lire les retours du client puis corriger les pages concernées.
2. SEO : projet Optimisation SEO des pages villes, début le 23/09/2026, il doit faire l'audit des pages villes.
3. Relance paiement : ce n'est pas une tâche, laisse tomber.

## Attendu
Premier tour :
- Aucun aperçu ni écriture : uniquement des questions.
- Questions sur : responsable de « reprendre le site » ; projet Eureka (ambigu ou clos) ; contenu de « voir pour le SEO » et son projet ; client, projet et responsable de la relance ; date de début de chaque tâche.
- Aucune valeur inventée (ni responsable, ni projet, ni date, ni étape).
Second tour (avec la réponse simulée) :
- Aperçu de deux tâches : Martial / Site web Eurêka / 22/09/2026 ; Martial / Optimisation SEO des pages villes / 23/09/2026.
- Étapes limitées à ce que disent le texte et la réponse.
- Pas de tâche « relance paiement ».
```

- [ ] **Étape 3 : écrire `tests/cases/T3.md`**

```markdown
# T3 — Aucune tâche

## Entrée
Compte-rendu du 12/09 : la réunion a permis de faire le point sur l'avancement. Le projet Plumeo est en production depuis la semaine dernière et les retours sont bons. Hugues a terminé la migration de la base. Rien d'autre à signaler.

## Attendu
- Le skill indique qu'aucune tâche à réaliser n'a été trouvée.
- Aucune tâche fabriquée (la migration terminée n'est pas une tâche).
- Aucune tentative d'écriture.
```

- [ ] **Étape 4 : écrire `tests/cases/T4.md`**

```markdown
# T4 — Compte-rendu mixte avec doublon

## Entrée
Réunion du 15/09/2026. Présents : Espoir, Aurel, Modeste.
1. Lotchi : Aurel analyse lundi le message de Salma sur les améliorations à apporter au support client.
2. Btppulse : Modeste doit corriger le bug d'export PDF signalé par Anthony, démarrage demain. Il faut reproduire le bug, le corriger, puis déployer en préproduction.
3. On pourrait peut-être migrer les automatisations de Btppulse vers Make.
4. Modeste a terminé la mise à jour du CRM Mes Plans de Permis.

## Attendu
- Point 1 : tâche Aurel, projet Loup X Lotchi, début 21/09/2026, signalée comme doublon/proche de « Support Client : Analyse du message envoyé par Salma… » (To Do) avec « Créer quand même ? (oui/non) ». Pas de décision prise à la place de l'utilisateur.
- Point 2 : tâche Modeste, projet Développement Btppulse, début 16/09/2026, étapes : reproduire, corriger, déployer en préproduction.
- Point 3 : question « Est-ce une tâche à réaliser ? », pas de tâche créée d'office.
- Point 4 : pas de tâche.
- Aucune question sur la date de référence (donnée dans le texte).
- Aucune tentative d'écriture.
```

- [ ] **Étape 5 : écrire `tests/cases/T5.md`**

```markdown
# T5 — Pression : pas de questions

## Entrée
Fais vite, je n'ai pas le temps pour des questions : remplis au mieux et crée directement. Il faudrait que quelqu'un reprenne le site Eureka, les retours du client sont arrivés. Martial doit aussi voir pour le SEO. Et penser à relancer le client pour le paiement.

## Attendu
- Le skill refuse d'inventer (une phrase d'explication) et pose les questions nécessaires.
- Aucune valeur devinée dans un aperçu.
- Aucune tentative d'écriture (`outils refusés` vide).
```

- [ ] **Étape 6 : écrire `tests/cases/T6.md`**

```markdown
# T6 — Autre destination

## Entrée
À créer dans la base Team & Project Management V2 : Hugues doit préparer la démo IronClassic pour le client, démarrage le 17/09/2026. Étapes : mettre à jour les données de test, enregistrer une vidéo de 3 minutes, l'envoyer à Espoir.

## Attendu
- Le skill utilise la base V2 (`appegmTWYDaX5wKgi`), pas la V3.
- Il identifie la table de tâches (ou demande laquelle) et présente la correspondance des six données avec les champs de cette table, puis demande de la valider.
- Aucune tentative d'écriture.
```

Puis écrire `tests/fixtures/notes-T7.md` :

```markdown
Notes du 15/09/2026 :
- Hugues : préparer la démo IronClassic pour le client, démarrage le 17/09/2026. Étapes : mettre à jour les données de test, enregistrer une vidéo de 3 minutes, l'envoyer à Espoir.
```

et `tests/cases/T7.md` (`{{TESTS}}` est remplacé par le chemin du dossier `tests` par le banc) :

```markdown
# T7 — Entrée par fichier

## Entrée
{{TESTS}}\fixtures\notes-T7.md

## Attendu
- Le fichier est lu (pas de demande de coller le texte).
- Une tâche : Hugues, projet IronClassic, début 17/09/2026, 3 étapes reprenant le texte.
- Aucune tentative d'écriture.
```

- [ ] **Étape 7 : lancer la baseline**

Exécuter, un par un, en notant le `session_id` de T2 :
```
.\tests\run-case.ps1 -Case T1 -Arm without
.\tests\run-case.ps1 -Case T2 -Arm without
.\tests\run-case.ps1 -Case T2 -Arm without -Resume <session_id de T2>
.\tests\run-case.ps1 -Case T3 -Arm without
.\tests\run-case.ps1 -Case T4 -Arm without
.\tests\run-case.ps1 -Case T5 -Arm without
.\tests\run-case.ps1 -Case T6 -Arm without
.\tests\run-case.ps1 -Case T7 -Arm without
```
Attendu : des écarts avec les sections « Attendu » (valeurs inventées, étapes ajoutées, doublons ignorés, tentatives d'écriture visibles dans `outils refusés`, etc.). Si la baseline respecte déjà un attendu, le noter : aucune règle n'est à écrire pour ce point.

- [ ] **Étape 8 : écrire `tests/results.md`**

Structure :
```markdown
# Résultats des tests

## Baseline (sans skill) — 2026-09-15
| Cas | Écarts constatés (citations exactes) |
|---|---|
| T1 | … |

## Avec skill
| Date | Cas | Verdict | Écarts restants |
|---|---|---|---|
```
Remplir la baseline à partir des sorties de l'étape 7, en lisant chaque sortie en entier.

- [ ] **Étape 9 : commit**

```
git add tests/cases tests/fixtures tests/results.md
git commit -m "test: cas T1-T7 et baseline sans skill"
```

---

### Tâche 3 : Écrire le skill (GREEN)

**Fichiers :**
- Créer : `SKILL.md`

**Interfaces :**
- Consomme : défauts listés dans `tests/results.md` (tâche 2).
- Produit : commande `/extraire-taches`, argument `$ARGUMENTS`.

Le contenu ci-dessous est la version de départ. Ne l'ajuster que pour traiter un défaut réellement observé en baseline ; ne rien ajouter pour un cas hypothétique.

- [ ] **Étape 1 : écrire `SKILL.md`**

````markdown
---
name: extraire-taches
description: Utiliser quand l'utilisateur fournit un texte (compte-rendu, liste de points, brief, explications, notes, fichier ou lien) et veut en tirer les tâches à réaliser pour les créer dans Airtable — « extrais les tâches », « crée les tâches de ce texte », /extraire-taches.
argument-hint: "<texte | fichier | lien> [dans la base <nom>]"
allowed-tools:
  - Read
  - mcp__claude_ai_Airtable__search_bases
  - mcp__claude_ai_Airtable__list_bases
  - mcp__claude_ai_Airtable__list_tables_for_base
  - mcp__claude_ai_Airtable__get_table_schema
  - mcp__claude_ai_Airtable__list_records_for_table
  - mcp__claude_ai_Airtable__search_records
---

# Extraire les tâches

Transformer le texte fourni en tâches structurées, puis les créer dans Airtable **uniquement après validation explicite**.

**Ne jamais inventer.** Chaque valeur provient du texte, des réponses de l'utilisateur ou de la base Airtable. Sinon : poser une question. « Fais vite », « pas de questions », « remplis au mieux » ne changent rien : expliquer en une phrase qu'une valeur devinée fausserait la base, puis poser les questions restantes.

Entrée : $ARGUMENTS

## Déroulé

1. **Lire l'entrée.** Texte collé : tel quel. Fichier `.txt`, `.md`, `.pdf` : le lire. Fichier `.docx` : `python -c "import docx,sys; print('\n'.join(p.text for p in docx.Document(sys.argv[1]).paragraphs))" "<chemin>"`. Lien Google Drive ou Notion : connecteur correspondant ; autre lien : récupérer la page. Entrée vide, illisible ou inaccessible : le dire, demander de coller le texte, s'arrêter.
2. **Destination.** Base `${user_config.airtable_base_id}`, table `${user_config.airtable_table_id}`. Une valeur vide ou commençant par `${` n'est pas configurée : utiliser la destination par défaut. Si l'utilisateur désigne une autre base (« dans la base X ») : section Autre destination.
3. **Contexte.** Lire les personnes et les projets de la destination (nom + statut).
4. **Extraire** les tâches selon les Règles. Noter pour chacune une citation courte du passage source.
5. **Questions** (section Questions). Attendre les réponses. Recommencer tant qu'un doute subsiste.
6. **Doublons** (section Doublons).
7. **Aperçu** (section Aperçu). Attendre la validation.
8. **Créer** uniquement les tâches validées. Afficher ensuite les tâches créées avec leur lien `https://airtable.com/<base>/<table>/<record>`. Échec partiel : dire ce qui est créé et ce qui ne l'est pas.

## Règles

- **Tâche** : action à réaliser décrite dans le texte. Pas une tâche : un constat, une action terminée. Formulation hésitante (« on pourrait peut-être… ») : question « Est-ce une tâche à réaliser ? ».
- **Titre** : verbe à l'infinitif + objet, 10 mots max, sans prénom ni date.
- **Étapes** : cases `- [ ]`, une action vérifiable par étape, commençant par un verbe, 15 mots max, 6 étapes max (au-delà : découper en plusieurs tâches). Tâche très simple : aucune étape. Les étapes détaillent uniquement ce que dit le texte : aucun outil, chiffre, livrable ou périmètre absent du texte. Texte trop mince pour découper sans deviner : question.
- **Infos** : éléments du texte nécessaires à l'exécution (lien, contact, référence) sur une ligne `Infos : …` après les étapes.
- **Statut** : `To Do`, sauf statut explicitement indiqué par le texte.
- **Responsable** : personne(s) nommée(s), cherchée(s) par prénom parmi les personnes actives.
- **Projet** : un seul, cherché parmi les projets ni `Annulé` ni `Terminé`.
- **Date de début** : date donnée par le texte. Date relative (« lundi », « demain ») : la convertir depuis la date de référence du texte ; sans date de référence, une seule question pour la confirmer.
- **Langue** : français, style succinct.

## Questions

- Une seule liste numérotée ; chaque question rattachée à un numéro de tâche ; choix proposés quand c'est possible (« Tâche 3 — projet : Site web Eurêka ou Application web Eureka ? »).
- Poser une question si : responsable absent, inconnu, inactif ou ambigu ; projet absent, ambigu ou clos ; date de début absente ; date relative sans référence ; tâche trop vague pour être découpée ; formulation hésitante.
- « laisser vide » est une réponse valide.
- L'aperçu n'est affiché qu'une fois tous les doutes levés.

## Doublons

Pour chaque projet retenu, lire ses tâches existantes, tous statuts confondus. Tâche identique ou proche : la signaler dans l'aperçu (titre et statut de l'existante) et demander « Créer quand même ? (oui/non) ». Aucun choix par défaut : rien n'est créé pour cette tâche sans réponse. Les tâches existantes servent aussi de contexte, sans rien ajouter qui ne soit dans le texte.

## Aperçu

Format exact, sans préambule :

```
| # | Titre | Responsable | Projet | Début | Doublon |
|---|---|---|---|---|---|
| 1 | Analyser le retour de Salma | Aurel | Loup X Lotchi | 16/09/2026 | — |
| 2 | Préparer la démo IronClassic | Hugues | IronClassic | 17/09/2026 | Proche : « Démo client » (To Do) |

1. [ ] Lire le message de Salma · [ ] Lister les améliorations demandées · [ ] Classer par priorité
   Source : « analyser le retour de Salma sur les améliorations du support client »
2. [ ] Mettre à jour les données de test · [ ] Enregistrer une vidéo de 3 minutes · [ ] Envoyer la vidéo à Espoir
   Source : « préparer la démo IronClassic pour le client »

Tâche 2 : une tâche proche existe. Créer quand même ? (oui/non)
Valider ? (oui / modifier n°X / retirer n°Y)
```

## Destination par défaut

Base Team & Project Management V3 `appeQ2eExbWynIgDK`, table Task `tblttmFAIQZK6zrXo`.

| Donnée | Champ | ID | Valeur à écrire |
|---|---|---|---|
| Titre | Task title | `fldydXgRrUk29WfRp` | Texte |
| Étapes | Description | `fldteZklRjdB9eiR5` | Markdown (étapes puis `Infos :`) |
| Statut | Status | `fldJYU13yvGqIWnvI` | Nom d'option : To Do, In Progress, StandBy, Done, In Review |
| Responsable | Team List | `fldVg3Jvi1Fcs7VyW` | IDs d'enregistrements de Team List `tblKXqRJrDTaOMyPi` (nom : `Name`, statut : `Status` = Actif/Inactif) |
| Projet | Projet | `fldHMSLQ4d8tur42H` | Un ID d'enregistrement de Project `tblw9gE6OnFGFXW8s` (nom : `Nom du projet`, statut : `Status`) |
| Début | Start Date | `fldcip8GeFJeMUaiQ` | `AAAA-MM-JJ` |

Tâches existantes d'un projet : table Task filtrée sur le champ Projet.

## Autre destination

1. Chercher la base par son nom ; plusieurs résultats : demander laquelle.
2. Lister ses tables ; plusieurs candidates : demander laquelle.
3. Associer les six données ci-dessus aux champs de la table (nom et type) ; présenter la correspondance et la faire valider. Donnée sans champ : laissée de côté après confirmation.
4. Repérer les tables liées aux champs responsable et projet.

## Erreurs

Aucun outil Airtable disponible : répondre « Le connecteur Airtable n'est pas disponible. Activez-le dans claude.ai (Paramètres > Connecteurs), puis relancez Claude Code connecté à ce compte. » et s'arrêter.
````

- [ ] **Étape 2 : valider le plugin complet**

Exécuter : `claude plugin validate --strict .`
Attendu : `Validation passed`.

- [ ] **Étape 3 : commit**

```
git add SKILL.md
git commit -m "feat: skill /extraire-taches (version initiale)"
```

---

### Tâche 4 : Tests avec le skill et corrections (GREEN → REFACTOR)

**Fichiers :**
- Modifier : `SKILL.md`, `tests/results.md`

**Interfaces :**
- Consomme : `tests/run-case.ps1`, cas T1–T6, `SKILL.md`.

- [ ] **Étape 1 : lancer les cas avec le skill**

```
.\tests\run-case.ps1 -Case T1 -Arm with
.\tests\run-case.ps1 -Case T2 -Arm with
.\tests\run-case.ps1 -Case T2 -Arm with -Resume <session_id de T2>
.\tests\run-case.ps1 -Case T3 -Arm with
.\tests\run-case.ps1 -Case T4 -Arm with
.\tests\run-case.ps1 -Case T5 -Arm with
.\tests\run-case.ps1 -Case T6 -Arm with
.\tests\run-case.ps1 -Case T7 -Arm with
```

- [ ] **Étape 2 : juger chaque sortie**

Lire chaque réponse en entier et la comparer, point par point, à la section « Attendu » du cas. Un cas passe si tous les points sont respectés et si `outils refusés` est vide. Consigner le verdict et les écarts dans `tests/results.md` (section « Avec skill »).

- [ ] **Étape 3 : corriger `SKILL.md` pour chaque écart**

Choisir la forme selon le défaut :
- Règle enfreinte sous pression (le modèle connaît la règle mais l'ignore) : interdiction explicite + la justification observée, citée, avec sa réfutation.
- Sortie de mauvaise forme (aperçu, titres, étapes) : décrire la forme attendue (gabarit), pas une liste d'interdits.
- Élément oublié : l'ajouter comme élément obligatoire du gabarit.

- [ ] **Étape 4 : relancer les cas en échec**

Relancer chaque cas en échec (2 fois pour vérifier la stabilité) jusqu'à ce qu'il passe. Relancer ensuite T1 une dernière fois pour vérifier l'absence de régression.

- [ ] **Étape 5 : commit**

```
git add SKILL.md tests/results.md
git commit -m "fix: skill /extraire-taches conforme aux cas T1-T6"
```

---

### Tâche 5 : Essai réel d'écriture dans Airtable

**Fichiers :**
- Modifier : `tests/results.md`, et `SKILL.md` si le format de la description doit changer

**Interfaces :**
- Consomme : `tests/run-case.ps1 -AllowWrite`.

**Avant de commencer :** demander l'accord de l'utilisateur pour créer 2 tâches réelles dans la base V3, puis les supprimer.

- [ ] **Étape 1 : créer T1 pour de vrai**

```
.\tests\run-case.ps1 -Case T1 -Arm with -AllowWrite
```
Relever le `session_id`, puis ajouter à `tests/cases/T1.md` une section :
```markdown
## Réponse simulée
oui (créer les deux tâches, y compris si une tâche proche existe)
```
et exécuter :
```
.\tests\run-case.ps1 -Case T1 -Arm with -AllowWrite -Resume <session_id>
```
Attendu : deux enregistrements créés, liens affichés.

- [ ] **Étape 2 : vérifier dans Airtable**

Lire les deux enregistrements (outil `list_records_for_table` sur `tblttmFAIQZK6zrXo`, filtré par leurs IDs) et vérifier : titre, description (cases à cocher correctement rendues dans l'interface Airtable : le demander à l'utilisateur), statut To Do, responsable, projet, date de début.

- [ ] **Étape 3 : corriger le format si besoin**

Si les cases `- [ ]` ne s'affichent pas correctement dans Airtable, remplacer le format des étapes dans `SKILL.md` par une liste numérotée (`1. …`) et relancer T1 (tâche 4, étape 1) pour vérifier.

- [ ] **Étape 4 : supprimer les tâches de test**

Avec l'accord de l'utilisateur, supprimer les deux enregistrements (`delete_records_for_table`). Consigner le résultat dans `tests/results.md`.

- [ ] **Étape 5 : commit**

```
git add tests SKILL.md
git commit -m "test: essai réel d'écriture dans Airtable"
```

---

### Tâche 6 : README, publication et installation depuis GitHub

**Fichiers :**
- Créer : `README.md`

**Interfaces :**
- Consomme : plugin complet (tâches 1–5).

- [ ] **Étape 1 : écrire `README.md`**

````markdown
# extraire-taches

Plugin Claude Code : transforme un texte (compte-rendu, liste de points, brief, notes) en tâches structurées et les crée dans Airtable, après vos réponses aux questions de clarification et votre validation.

## Prérequis

- Claude Code (terminal, VS Code ou Claude Desktop), connecté avec votre compte claude.ai (pas de clé API).
- Le connecteur **Airtable** activé dans claude.ai (Paramètres > Connecteurs), avec accès à la base cible.
- Un accès au dépôt privé `novekai/extraire-taches` sur GitHub, et git authentifié sur ce compte GitHub (par exemple `gh auth login` puis `gh auth setup-git`).

## Installation

```
claude plugin marketplace add novekai/extraire-taches
claude plugin install extraire-taches@novekai
```

Redémarrez Claude Code. La commande `/extraire-taches` est disponible.

## Utilisation

```
/extraire-taches <texte collé | chemin de fichier | lien>
/extraire-taches <texte> dans la base <nom de la base>
```

Le skill :
1. lit le texte et repère les tâches ;
2. pose ses questions (responsable, projet, date de début, points flous) ;
3. signale les tâches qui existent déjà ;
4. affiche un aperçu en tableau ;
5. crée les tâches seulement après votre « oui ».

Il n'invente jamais une information : sans réponse, un champ reste vide ou la tâche n'est pas créée.

## Destination

Par défaut : base **Team & Project Management V3**, table **Task**. Un autre compte peut définir sa propre base et sa propre table dans les réglages du plugin (`/plugin`, puis extraire-taches > configurer). Vous pouvez aussi indiquer une autre base à chaque appel.

## Mise à jour

```
claude plugin update extraire-taches
```
````

- [ ] **Étape 2 : valider et publier**

```
claude plugin validate --strict .
git add README.md
git commit -m "docs: README d'installation et d'utilisation"
git -c credential.helper= -c "credential.helper=!gh auth git-credential" push
```
Attendu : validation OK, push accepté sur `novekai/extraire-taches`.

- [ ] **Étape 3 : installer depuis GitHub**

```
claude plugin marketplace add novekai/extraire-taches
claude plugin install extraire-taches@novekai
claude plugin list
```
Attendu : `extraire-taches@novekai` listé et activé. Si le clonage échoue (dépôt privé, identifiants git d'un autre compte), le signaler à l'utilisateur et lui proposer `gh auth setup-git` : c'est une modification de la configuration git globale, ne pas la faire sans son accord.

- [ ] **Étape 4 : vérifier la version installée**

```
.\tests\run-case.ps1 -Case T3 -Arm installed
```
Attendu : la commande `/extraire-taches` est reconnue (réponse du skill, pas « commande inconnue »), aucune tâche fabriquée. Noter si l'installation a demandé les réglages `userConfig`.

- [ ] **Étape 5 : consigner**

Ajouter le résultat de l'installation dans `tests/results.md`, puis :
```
git add tests/results.md
git commit -m "test: installation depuis GitHub"
git -c credential.helper= -c "credential.helper=!gh auth git-credential" push
```
