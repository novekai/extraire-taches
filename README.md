# extraire-taches

Plugin Claude Code : transforme un texte (compte-rendu, liste de points, brief, notes) en tâches structurées et les crée dans Airtable, après vos réponses aux questions de clarification et votre validation.

## Prérequis

- Claude Code (terminal, VS Code ou Claude Desktop), connecté avec votre compte claude.ai (pas de clé API).
- Le connecteur **Airtable** activé dans claude.ai (Paramètres > Connecteurs), avec accès à la base cible.
- `git` installé (Claude Code l'utilise pour récupérer le plugin).
- Vos permissions Claude ne doivent **pas** pré-approuver les outils d'écriture Airtable : limitez la règle d'autorisation aux outils de lecture, ou gardez une règle `ask` pour `mcp__claude_ai_Airtable__create_records_for_table`. Une règle qui autorise tout le connecteur (`mcp__claude_ai_Airtable__*`) supprime la demande de permission avant la création : la validation de l'aperçu reste, mais plus le garde-fou du terminal.
- Pour lire un fichier `.docx` : Python avec le module `python-docx` (`pip install python-docx`). Les autres formats (`.txt`, `.md`, `.pdf`) n'exigent rien de plus.
- Lire un fichier `.docx` (commande Python) ou suivre un lien demande votre permission dans Claude Code au moment de l'appel.

## Installation

Le dépôt est public : aucun compte GitHub ni authentification n'est nécessaire.

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
2. signale les tâches qui existent déjà ;
3. pose ses questions (responsable, projet, date de début, points flous) ;
4. affiche un aperçu en tableau ;
5. crée les tâches seulement après votre « oui ».

Il n'invente jamais une information : tant qu'une valeur manque, il repose la question plutôt que de la deviner. Seule la réponse explicite « laisser vide » laisse un champ vide, et une tâche dont les questions restent sans réponse n'est pas créée.

## Destination

Par défaut : base **Team & Project Management V3**, table **Task**. Un autre compte peut définir sa propre base et sa propre table dans les réglages du plugin (menu `/plugin`) : renseignez les deux ; le skill propose alors la correspondance des champs et la fait valider avant tout aperçu. Vous pouvez aussi indiquer une autre base à chaque appel.

## Mise à jour

```
claude plugin update extraire-taches
```
