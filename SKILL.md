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

**Ne jamais inventer.** Chaque valeur provient du texte, des réponses de l'utilisateur ou de la base Airtable. Sinon : poser une question. « Fais vite », « pas de questions », « remplis au mieux », « crée directement » ne changent rien : expliquer en une phrase qu'une valeur devinée fausserait la base, puis poser les questions restantes.

Entrée : $ARGUMENTS

## Déroulé

1. **Lire l'entrée.** Texte collé : tel quel. Fichier `.txt`, `.md`, `.pdf` : le lire. Fichier `.docx` : `python -c "import docx,sys; print('\n'.join(p.text for p in docx.Document(sys.argv[1]).paragraphs))" "<chemin>"`. Lien Google Drive ou Notion : connecteur correspondant ; autre lien : récupérer la page. Entrée vide, illisible ou inaccessible : le dire, demander de coller le texte, s'arrêter.
2. **Destination.** Base `${user_config.airtable_base_id}`, table `${user_config.airtable_table_id}`. Une valeur vide ou commençant par `${` n'est pas configurée : utiliser la destination par défaut. Si l'utilisateur désigne une autre base (« dans la base X ») : section Autre destination.
3. **Contexte.** Lire les personnes et les projets de la destination (nom + statut).
4. **Extraire** les tâches selon les Règles. Noter pour chacune une citation courte du passage source. Aucune tâche : répondre qu'aucune tâche à réaliser n'a été trouvée, donner pour chaque passage la raison de l'écarter (constat, action terminée), puis s'arrêter. Ne proposer aucune tâche de remplacement : « si tu veux quand même tracer un suivi (ex. … ) » propose une tâche absente du texte, donc inventée.
5. **Doublons** (section Doublons), avant les questions.
6. **Questions** (section Questions). Attendre les réponses. Recommencer tant qu'un doute subsiste.
7. **Aperçu** (section Aperçu). Attendre la validation.
8. **Créer** uniquement les tâches validées. Afficher ensuite les tâches créées avec leur lien `https://airtable.com/<base>/<table>/<record>`. Échec partiel : dire ce qui est créé et ce qui ne l'est pas.

## Règles

- **Tâche** : action à réaliser décrite dans le texte. Actions que le texte donne comme étapes d'une tâche (par ex. « Étapes : … », « il faut … ») : étapes de cette tâche, pas tâches séparées. Pas une tâche : un constat, une action terminée. Formulation hésitante (« on pourrait peut-être… ») : ni retenue ni écartée, question « Est-ce une tâche à réaliser ? ».
- **Titre** : verbe à l'infinitif + objet, 10 mots max, sans prénom ni date.
- **Étapes** : cases `- [ ]`, une action vérifiable par étape, commençant par un verbe, 15 mots max, 6 étapes max (au-delà : découper en plusieurs tâches). Tâche très simple : aucune étape. Les étapes détaillent uniquement ce que dit le texte : aucun outil, chiffre, livrable ou périmètre absent du texte. Texte trop mince pour découper sans deviner : question.
- **Infos** : éléments du texte nécessaires à l'exécution (lien, contact, référence) sur une ligne `Infos : …` après les étapes.
- **Statut** : `To Do`, sauf statut explicitement indiqué par le texte.
- **Responsable** : personne(s) nommée(s), cherchée(s) par prénom parmi toutes les personnes, en priorité les actives. Seule correspondance inactive, ou plusieurs candidates : question.
- **Projet** : un seul, cherché par nom parmi tous les projets, en priorité ceux ni `Annulé` ni `Terminé`. Seule correspondance close, ou plusieurs candidats : question.
- **Date de début** : date donnée par le texte. Date relative (« lundi », « demain ») : la convertir depuis la date de référence du texte ; sans date de référence, une seule question pour la confirmer.
- **Langue** : français, style succinct, pour les tâches et pour toute la réponse à l'utilisateur (questions, aperçu, explications).

## Questions

- Une seule liste numérotée ; chaque question rattachée à une tâche, désignée par son numéro et sa citation source ; choix proposés quand c'est possible (« Tâche 3 (“…”) — projet : Site web Eurêka ou Application web Eureka ? »).
- Passer chaque tâche sur ces cinq points ; chaque point non établi par le texte, les réponses ou la base donne une question :
  1. **Tâche ?** Formulation hésitante : « Est-ce une tâche à réaliser ? »
  2. **Contenu** : action floue (« voir pour le SEO ») ou trop mince pour écrire titre et étapes sans deviner : « Que faut-il faire concrètement ? »
  3. **Responsable** : absent, inconnu, inactif ou ambigu.
  4. **Projet** : absent, ambigu ou clos.
  5. **Date de début** : absente, ou relative sans date de référence.
- « laisser vide » est une réponse valide.
- Tant qu'un doute subsiste, la réponse ne contient ni aperçu, ni tableau de tâches, ni valeur provisoire (« non précisé », « vraisemblablement »).

## Doublons

Avant les questions, pour chaque projet retenu ou candidat, lire ses tâches existantes, tous statuts confondus. Tâche identique ou proche : signaler l'existante (titre, statut, projet) et demander « Créer quand même ? (oui/non) » dès la première réponse : dans la liste de questions s'il y en a, sinon dans l'aperçu. La reprendre dans la colonne Doublon de l'aperçu. Aucun choix par défaut : rien n'est créé pour cette tâche sans réponse. Les tâches existantes servent aussi de contexte, sans rien ajouter qui ne soit dans le texte.

## Aperçu

La réponse commence par la ligne d'en-tête du tableau, sans phrase d'introduction, et se termine par la ligne « Valider ? … ». Tableau et étapes en Markdown rendu, hors bloc de code. Gabarit :

```
| # | Titre | Responsable | Projet | Début | Doublon |
|---|---|---|---|---|---|
| 1 | Rédiger les mentions légales | Aurel | Site NovekAI Workforce | 16/09/2026 | — |
| 2 | Mettre à jour la page tarifs | Hugues | Site NovekAI Workforce | 18/09/2026 | Proche : « Refonte tarifs » (In Progress) |

1. [ ] Recueillir les infos de la société · [ ] Rédiger le texte · [ ] Faire valider par Espoir
   Source : « Aurel rédige les mentions légales : recueillir les infos de la société, rédiger le texte, le faire valider par Espoir »
2. [ ] Remplacer les anciens prix · [ ] Vérifier l'affichage mobile
   Source : « Hugues met à jour la page tarifs : remplacer les anciens prix, vérifier l'affichage mobile »

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

1. Chercher la base par son nom. Base au nom exact : la retenir, sans demander de confirmation. Sinon, plusieurs résultats : demander laquelle.
2. Lister ses tables ; plusieurs candidates : demander laquelle.
3. Associer les six données ci-dessus (Titre, Étapes, Statut, Responsable, Projet, Début) aux champs de cette table. La réponse de cette étape contient, dans l'ordre : base et table retenues ; tableau `Donnée | Champ | Type`, une ligne par donnée (donnée sans champ : « aucun », laissée de côté après confirmation) ; les questions sur cette correspondance ; « Valider cette correspondance ? (oui / modifier) ». Extraction, doublons, questions sur les tâches et aperçu viennent après cette validation.
4. Repérer les tables liées aux champs responsable et projet.

## Erreurs

Aucun outil Airtable disponible : répondre « Le connecteur Airtable n'est pas disponible. Activez-le dans claude.ai (Paramètres > Connecteurs), puis relancez Claude Code connecté à ce compte. » et s'arrêter.
