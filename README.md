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

Par défaut : base **Team & Project Management V3**, table **Task**. Un autre compte peut définir sa propre base et sa propre table dans les réglages du plugin (menu `/plugin`). Vous pouvez aussi indiquer une autre base à chaque appel.

## Mise à jour

```
claude plugin update extraire-taches
```
