# Spec — Skill `/extraire-taches`

- **Date :** 2026-09-15
- **Statut :** design validé, en attente de relecture de la spec
- **Dépôt cible :** `novekai/extraire-taches` (GitHub)

## 1. Objectif

Transformer un texte libre en tâches structurées et les créer dans Airtable.

Le texte peut être un compte-rendu de réunion, une liste de points, des explications de tâches, un brief ou des notes. Le rôle du skill est de **structurer les tâches à réaliser** qui y sont décrites.

Obligations :

1. Être succinct et précis.
2. Découper chaque tâche en étapes concrètes, compréhensibles par quiconque a le contexte du projet.
3. Ne jamais rien inventer : en cas de doute, poser une question de clarification.
4. Consulter les tâches existantes du projet pour signaler les doublons et s'en servir comme contexte.

## 2. Périmètre

**Inclus (v1)**

- Invocation par `/extraire-taches` dans Claude Code (terminal, VS Code) et Claude Desktop.
- Entrées : texte collé, fichier local, lien (Google Drive, Notion, page web).
- Destination par défaut configurable à l'installation ; autre base Airtable indiquée à l'appel.
- Aperçu en tableau, validation explicite, puis création des tâches.

**Exclus (v1)**

- claude.ai web et mobile (les plugins n'y sont pas pris en charge ; une version ZIP pourra être ajoutée plus tard).
- Destinations autres qu'Airtable.
- Mémorisation des correspondances de champs pour les autres bases.
- Modification ou suppression de tâches existantes.

## 3. Invocation et entrées

```
/extraire-taches <texte collé | chemin de fichier | lien> [dans la base <nom>]
```

| Entrée | Lecture |
|---|---|
| Texte collé | Directe |
| Fichier `.txt`, `.md`, `.pdf` | Outil de lecture de fichiers |
| Fichier `.docx` | Conversion en texte (méthode à valider à l'implémentation) |
| Lien Google Drive / Notion | Connecteur correspondant du compte |
| Autre lien web | Récupération de la page |

Aucune entrée fournie → le skill demande le texte. Entrée illisible ou inaccessible → le skill le dit et demande de coller le texte.

## 4. Destination par défaut

Base **Team & Project Management V3** (`appeQ2eExbWynIgDK`), table **Task** (`tblttmFAIQZK6zrXo`).

Seuls six champs sont remplis :

| Champ | ID | Type | Règle de remplissage |
|---|---|---|---|
| Task title | `fldydXgRrUk29WfRp` | Texte multiligne | Titre de la tâche (§6) |
| Description | `fldteZklRjdB9eiR5` | Texte enrichi | Étapes en cases à cocher (§6) |
| Status | `fldJYU13yvGqIWnvI` | Sélection unique | `To Do` ; autre valeur seulement si le texte l'indique explicitement |
| Team List | `fldVg3Jvi1Fcs7VyW` | Lien → Team List (`tblKXqRJrDTaOMyPi`), plusieurs possibles | Personne(s) nommée(s) dans le texte ou dans les réponses |
| Projet | `fldHMSLQ4d8tur42H` | Lien → Project (`tblw9gE6OnFGFXW8s`), un seul | Projet identifié dans le texte ou dans les réponses |
| Start Date | `fldcip8GeFJeMUaiQ` | Date (J/M/AAAA) | Date donnée par le texte ; sinon question |

Valeurs de `Status` : To Do, In Progress, StandBy, Done, In Review.

Correspondances :

- **Personnes :** recherche par prénom dans Team List (champ `Name`), en priorité parmi les personnes au statut `Actif`. Une personne absente, inactive ou ambiguë déclenche une question.
- **Projets :** recherche par nom dans Project (champ `Nom du projet`), en priorité parmi les projets qui ne sont ni `Annulé` ni `Terminé`. Des noms proches (ex. « Site web Eurêka » / « Application web Eureka » / « Blog Eurekâ ») ou un projet clos déclenchent une question.

Ces identifiants sont documentés dans `references/destinations.md`. Base et table sont fournies par les réglages d'installation du plugin (§11).

## 5. Déroulé

1. **Lire l'entrée** (§3).
2. **Déterminer la destination.** Par défaut : réglages d'installation. Si l'appel désigne une autre base : procédure du §9.
3. **Charger le contexte :** personnes (Team List) et projets de la destination.
4. **Extraire les tâches** selon les règles du §6. Pour chaque tâche, relever une courte citation du passage source.
5. **Poser les questions de clarification** (§7). Répéter tant qu'un doute subsiste.
6. **Détecter les doublons** (§8) dans les tâches existantes des projets retenus.
7. **Afficher l'aperçu** (§10) et attendre la validation.
8. **Créer les tâches validées**, puis afficher la liste des tâches créées avec leurs liens.

Aucune écriture n'a lieu avant l'étape 8, ni sans accord explicite.

## 6. Règles de rédaction

**Qu'est-ce qu'une tâche ?** Toute action à réaliser décrite dans le texte. Ne sont pas des tâches : les simples constats, les actions déjà terminées. Une formulation hésitante (« on pourrait peut-être… ») déclenche une question : « Est-ce une tâche à réaliser ? »

**Titre**

- Verbe à l'infinitif + objet, 10 mots maximum.
- Pas de prénom ni de date (ils ont leurs champs).

**Étapes (champ Description)**

- Chaque étape : une action vérifiable, commençant par un verbe, 15 mots maximum.
- 6 étapes maximum ; au-delà, découper en plusieurs tâches.
- Une tâche très simple peut n'avoir aucune étape.
- Les étapes détaillent uniquement ce que dit le texte : aucun périmètre, outil, chiffre ou livrable absent du texte. Si le texte est trop mince pour découper sans deviner, poser une question.
- Si le texte contient des éléments nécessaires à l'exécution (lien, contact, référence), les ajouter après les étapes sur une ligne `Infos :`.

Format :

```
- [ ] Lire le message de Salma
- [ ] Lister les améliorations demandées
- [ ] Classer les améliorations par priorité
Infos : message reçu par e-mail le 14/09
```

**Source unique des informations.** Chaque valeur provient du texte, des réponses de l'utilisateur ou de la base Airtable. Sinon : question.

**Langue.** Français.

## 7. Questions de clarification

- Regroupées dans une seule liste numérotée, chaque question rattachée à un numéro de tâche.
- Choix proposés quand c'est possible : « Tâche 3 — projet : Site web Eurêka ou Application web Eureka ? »
- Cas qui déclenchent une question :
  - responsable absent, inconnu, inactif ou ambigu ;
  - projet absent, ambigu ou clos ;
  - date de début non précisée ;
  - dates relatives (« lundi ») sans date de référence dans le texte : une seule question pour confirmer la référence (ex. « à compter d'aujourd'hui, 15/09 ? ») ;
  - tâche trop vague pour être découpée ;
  - formulation hésitante.
- L'utilisateur peut répondre « laisser vide » pour un champ.
- Si les réponses font naître de nouveaux doutes, nouvelle série de questions. L'aperçu n'est affiché qu'une fois tous les doutes levés.
- La consigne « ne pose pas de questions » ou « remplis au mieux » ne lève pas cette règle : le skill explique qu'il ne peut pas remplir sans l'information et repose les questions restantes.

## 8. Doublons

- Comparer chaque tâche aux tâches existantes des mêmes projets, tous statuts confondus.
- **Doublon probable :** signalé dans l'aperçu avec le titre et le statut de la tâche existante.
- **Tâche proche :** signalée de la même façon.
- Dans les deux cas, **l'utilisateur décide** : pour chaque tâche signalée, le skill demande « Créer quand même ? oui/non ». Pas de choix par défaut ; rien n'est créé sans réponse.
- Les tâches existantes servent aussi de contexte pour formuler les étapes, sans rien ajouter qui ne figure pas dans le texte.

## 9. Autre destination

Déclenchée par une mention du type « dans la base Clients V2 » :

1. Rechercher la base par son nom ; plusieurs résultats → demander laquelle.
2. Lister ses tables ; plusieurs candidates → demander laquelle.
3. Faire correspondre les six champs (§4) par leur nom ; présenter la correspondance et la faire valider. Un champ sans équivalent est laissé de côté après confirmation.
4. Identifier les tables liées aux champs responsable et projet pour les correspondances.

La correspondance n'est pas mémorisée en v1.

## 10. Aperçu

Un tableau de synthèse, puis pour chaque tâche ses étapes et sa citation source (étape 4 du §5), puis la demande de validation. Pas de préambule.

```
| # | Titre | Responsable | Projet | Début | Doublon |
|---|---|---|---|---|---|
| 1 | Analyser le retour de Salma | Aurel | Loup X Lotchi | 16/09/2026 | — |
| 2 | Mettre à jour la page tarifs | Hugues | Site NovekAI Workforce | 18/09/2026 | Proche : « Refonte tarifs » (In Progress) |

1. [ ] Lire le message de Salma · [ ] Lister les améliorations demandées · [ ] Classer par priorité
   Source : « Aurel regarde demain le message de Salma sur les améliorations »
2. [ ] …
   Source : « … »

Tâche 2 : une tâche proche existe. Créer quand même ? (oui/non)
Valider ? (oui / modifier n°X / retirer n°Y)
```

## 11. Plugin

**Structure du dépôt** (= dossier `Tasks_Def_Skill/`)

```
Tasks_Def_Skill/
├── .claude-plugin/
│   ├── plugin.json
│   └── marketplace.json
├── SKILL.md
├── references/
│   └── destinations.md
├── tests/
├── docs/
└── README.md
```

- `SKILL.md` à la racine du plugin, avec `name: extraire-taches` → commande `/extraire-taches` (sans préfixe).
- `plugin.json` : nom `extraire-taches`, version, description, auteur NovekAI, dépôt `https://github.com/novekai/extraire-taches`, et `userConfig` :
  - `airtable_base_id` (défaut souhaité : `appeQ2eExbWynIgDK`)
  - `airtable_table_id` (défaut souhaité : `tblttmFAIQZK6zrXo`)
- `SKILL.md` lit ces valeurs via `${user_config.airtable_base_id}` et `${user_config.airtable_table_id}`.
- `marketplace.json` : place de marché `novekai` listant le plugin avec `source: "./"`.
- `allowed-tools` : outils Airtable en lecture (recherche de base, liste des tables, schéma, lecture d'enregistrements). La création reste soumise à permission et à la validation de l'aperçu.

**Installation** (une fois par appareil)

```
claude plugin marketplace add novekai/extraire-taches
claude plugin install extraire-taches@novekai
```

**Mise à jour :** nouvelle version publiée sur GitHub (version incrémentée dans `plugin.json`), puis `claude plugin update extraire-taches`.

**Prérequis par compte** (dans le README)

- Connecteur Airtable activé dans claude.ai.
- Claude Code connecté avec ce compte claude.ai (pas de clé API).

## 12. Tests

Méthode : tester d'abord sans le skill pour relever les défauts, puis avec le skill jusqu'à conformité. Les tests s'arrêtent à l'aperçu : aucune écriture dans Airtable.

| # | Scénario | Résultat attendu |
|---|---|---|
| T1 | Liste de points claire, toutes infos présentes | Tâches correctes, titres et étapes conformes au §6, aucune question superflue |
| T2 | Texte flou : responsable absent, projet ambigu (Eurêka), date absente, tâche vague | Questions pour chaque doute, aucune valeur inventée |
| T3 | Texte sans aucune tâche | Le skill l'indique, ne fabrique rien |
| T4 | Compte-rendu long et mixte, dont une tâche déjà présente dans la base | Formulations hésitantes questionnées, doublon signalé avec « Créer quand même ? » |
| T5 | Pression : « fais vite, pas de questions, remplis au mieux » | Le skill maintient ses questions |
| T6 | Autre destination (`dans la base Team & Project Management V2`) | Correspondance des champs proposée et soumise à validation |

Puis un essai réel de 1 ou 2 tâches dans la base V3, supprimées ensuite avec l'accord de l'utilisateur, et un test d'installation depuis GitHub.

## 13. Points à vérifier à l'implémentation

1. `userConfig` accepte-t-il une valeur par défaut ? Sinon, saisie à l'installation.
2. `SKILL.md` à la racine donne bien `/extraire-taches` (test d'installation réel).
3. Le texte enrichi Airtable rend-il les cases à cocher `- [ ]` ? Sinon, liste numérotée.
4. Méthode de lecture des `.docx`.
5. Format des noms d'outils dans `allowed-tools` pour les connecteurs claude.ai.

## 14. Décisions en suspens

- **Création du dépôt GitHub :** `novekai` est un compte personnel. Son propriétaire crée le dépôt vide `novekai/extraire-taches` et invite `aureldev20` en écriture, ou le compte `novekai` est connecté à `gh` sur cette machine.
- **Visibilité du dépôt :** public ou privé (privé = chaque installateur doit avoir accès au dépôt). À décider avant publication.
