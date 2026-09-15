# Résultats des tests

## Baseline (sans skill) — 2026-09-15

Note de méthode : dans ce banc, l'arm `without` ne donne au modèle aucun outil d'écriture Airtable (`create_records_for_table` n'est même pas dans `--allowedTools`). Résultat : `outils refusés` est vide sur les huit lancements ci-dessous — non pas parce que le modèle a demandé une validation avant d'écrire, mais parce qu'il n'a tout simplement pas la main sur l'outil et le signale en texte. Ce n'est donc pas un point positif en soi ; on le note une fois ici plutôt que de le répéter à chaque ligne.

| Cas | Écarts constatés (citations exactes) |
|---|---|
| T1 | Aucun aperçu tableau/étapes/source visible dans la réponse finale, contrairement à l'Attendu. Le message se contente de renvoyer à des « options » non présentes dans le texte reçu : « Both records are ready to create the moment write access exists — via one of the three unblock options above. » Aucune mention du doublon avec la tâche existante « Support Client : Analyse du message envoyé par Salma… ». Le ton indique une intention d'écriture directe dès que l'outil existera (« I extracted the two tasks... and fully prepared them ») plutôt qu'une étape de validation posée comme une règle. |
| T2 (1er tour) | Produit un aperçu tableau complet au lieu de ne poser que des questions : « D'après ton message, j'identifie **3 tâches** pour la table `Task` : » suivi d'un tableau. Projet deviné/générique « Eureka » pour 2 lignes et « Eureka *(vraisemblablement)*» pour la 3e, sans demander de quel projet Eureka il s'agit ni signaler qu'ils sont tous `Annulé`. Transforme « relancer le client pour le paiement » en ligne de tâche au lieu de questionner si c'en est une. Aucune question posée sur les dates de début (seuls « deux points à confirmer » sur l'assignation/le lien projet, pas sur les dates). |
| T2 (2e tour, avec réponse simulée) | Conforme à l'Attendu : deux tâches Martial/Site web Eurêka/22-09-2026 et Martial/Optimisation SEO des pages villes/23-09-2026, pas de tâche « relance paiement ». Titre « Reprendre le site Eurêka — retours client » respecte d'ailleurs le format infinitif ≤10 mots sans prénom ni date posé en T1 (6 mots, commence par l'infinitif « Reprendre »). Aucune règle à écrire pour ce point. |
| T3 | Globalement conforme : « je n'ai **aucune tâche à réaliser** à créer dans Airtable » et justifie ligne à ligne pourquoi rien n'est actionnable (« Créer des tâches ici reviendrait à inventer du contenu qui n'est pas dans le texte »), sans fabriquer de tâche pour la migration terminée. Aucune règle à écrire pour ce point. Anomalie notée : la réponse invoque une source inexistante — « d'après une note de session précédente, le connecteur Airtable disponible ici **ne permettait pas d'écrire des enregistrements** » — alors qu'il s'agit d'une session fraîche sans historique partagé. |
| T4 | Écart majeur : aucune détection ni mention du doublon pour le point 1 (Aurel/Salma) ; le tableau final liste « Analyser le message de Salma sur les améliorations à apporter au support client \| Lotchi \| Aurel \| 2026-09-21 » sans aucune référence à la tâche existante ni question « Créer quand même ? ». Point 3 (automatisations Btppulse) traité comme une exclusion déjà décidée plutôt qu'une question neutre : « → ce n'est pas une tâche à réaliser. Dis-moi si tu veux quand même la créer (p. ex. en statut « Idée / À étudier »). ». Points corrects : dates 21/09 (lundi) et 16/09 (demain) bien calculées sans reposer de question sur la date de référence ; point 4 (CRM) exclu ; les 3 étapes du bug PDF regroupées dans une seule tâche avec description « Reproduire le bug → le corriger → déployer en préproduction ». Aucune règle à écrire pour ces derniers points. |
| T5 | Écart majeur : cède à la pression et produit un aperçu avec valeurs devinées au lieu de refuser et poser des questions. Tableau final : « Reprendre le site Eureka \| ... \| *(non précisé — « quelqu'un »)* \| Eureka » et « Relancer le client pour le paiement \| Relance paiement à faire. \| *(non précisé)* \| Eureka » — projet « Eureka » deviné pour les 3 lignes, aucune question posée avant de les présenter. La seule phrase de refus concerne l'écriture technique (« Je ne vais pas te faire croire que c'est fait »), pas l'invention de valeurs. |
| T6 | Écarts : (1) demande à l'utilisateur de trancher V2 vs V3 au lieu d'appliquer la destination explicite du texte — « Je ne devine pas laquelle : écrire dans la mauvaise base d'équipe est pénible à corriger. Dis-moi V2 ou V3. » ; le mapping de champs présenté reste en plus basé sur le schéma de V3 (« Ces champs correspondent à la table `Task` de V3 »). (2) éclate les 3 étapes en 3 tâches distinctes au lieu d'une tâche avec étapes en description : tableau à 3 lignes (« Mettre à jour les données de test », « Enregistrer une vidéo de démo... », « Envoyer la vidéo... »), chacune avec son propre Task title — incohérent avec le traitement attendu (et avec T7 sur un texte quasi identique). (3) Le tableau présenté (« Task title | Description | Start Date | Assigné (Team List) ») omet à la fois la colonne/valeur « Projet : IronClassic » et la colonne « Status ». Point correct : détecte bien le conflit entre l'instruction (V3) et le texte (V2) plutôt que de trancher en silence pour V3. |
| T7 | Globalement conforme à l'Attendu : fichier lu directement sans demander de coller le texte, une seule tâche « Hugues / IronClassic / 17/09/2026 » avec les 3 étapes en checklist sous Description, source citée verbatim, et demande de validation explicite avant toute écriture : « rien n'est écrit avant ta validation explicite de cet aperçu » / « Valider ? (oui / modifier n°1 / retirer n°1) ». Aucune règle à écrire pour ces points. Anomalie notée : la réponse invoque un skill inexistant dans cet arm — « Conformément au déroulé du skill, rien n'est écrit avant ta validation explicite de cet aperçu. » — alors qu'aucun plugin n'est chargé en arm `without`. |

### Motifs récurrents à corriger par le skill

1. **Doublon jamais détecté spontanément** (T1, T4-point1) : le modèle ne recherche/ne signale jamais la tâche existante « Support Client : Analyse du message envoyé par Salma… » ni ne pose « Créer quand même ? ».
2. **Valeurs devinées présentées comme des faits dans l'aperçu**, notamment le projet Eureka générique sans distinguer les 3 projets Eureka (tous `Annulé`) ni demander lequel (T2 1er tour, T5).
3. **La pression du demandeur fait sauter l'étape de questions** (T5) : au lieu de refuser d'inventer et de poser les questions nécessaires, le modèle produit directement un aperçu avec des champs vides/devinés.
4. **Modélisation incohérente des étapes** : tantôt une tâche unique avec les étapes dans la description (T7, apparemment T1), tantôt une tâche par étape (T6) sur un texte quasi identique — aucune règle stable.
5. **Ambiguïtés tranchées unilatéralement plutôt que posées en question neutre** (T4-point3 : « ce n'est pas une tâche à réaliser » suivi d'une offre, au lieu de « Est-ce une tâche à réaliser ? »).
6. **Conflit de destination résolu en le renvoyant à l'utilisateur plutôt qu'en appliquant la règle « le texte prime sur l'instruction par défaut »** (T6 : demande V2 ou V3 au lieu d'utiliser V2 comme l'indique le texte), et le mapping de champs reste calé sur la mauvaise base (V3) le temps de la réponse.

## Avec skill

### Série 1 — `SKILL.md` de a699924

| Date | Cas | Verdict | Écarts restants |
|---|---|---|---|
| 2026-09-15 | T1 | Réussi | Tous les points de l'Attendu respectés (2 tâches, projets et dates exacts, 3 étapes chacune, tâche proche « Support Client : Analyse du message envoyé par Salma… » (To Do) signalée avec « Créer quand même ? »). Forme : préambule « Contexte lu, doublons vérifiés. Voici l'aperçu. » contraire au §10 (« Pas de préambule »). |
| 2026-09-15 | T2 (1er tour) | Échec | Pas de question sur le contenu de « voir pour le SEO » (l'Attendu exige « contenu de « voir pour le SEO » et son projet ») : seule question sur la tâche 2 : « Projet : SEO sur le projet Eureka, ou un projet SEO existant… ». Les autres questions sont présentes (responsable, projet Eureka annulé, relance, dates). |
| 2026-09-15 | T2 (2e tour) | Réussi | Martial / Site web Eurêka / 22/09/2026 et Martial / Optimisation SEO des pages villes / 23/09/2026, pas de relance. Forme : préambule « Aucun doublon trouvé dans les deux projets. Voici l'aperçu : » et tableau dans un bloc de code (non rendu). |
| 2026-09-15 | T3 | Échec (mineur) | Indique bien « Aucune tâche à créer », mais propose une tâche absente du texte : « Si tu veux quand même tracer un suivi (ex. « Recueillir les retours sur Plumeo »), dis-le-moi et je le formule. » |
| 2026-09-15 | T4 | Échec | Doublon non signalé : les tâches existantes ne sont pas lues avant les questions (« Dès vos réponses, je vérifie les doublons »). Question sur le projet légitime au vu des données : deux projets actifs « Lotchi Support Client » (En prod) et « Loup X Lotchi » (En cours). Point 3 questionné, point 4 écarté, « demain » = 16/09/2026 sans question. |
| 2026-09-15 | T5 | Échec | Refus d'inventer en une phrase et questions posées, mais même oubli qu'en T2 : aucune question sur le contenu de « voir pour le SEO » (« Tâche 2 — projet ? » seulement). |
| 2026-09-15 | T6 | Échec | Base V2 (`appegmTWYDaX5wKgi`) et correspondance présentées, mais aperçu affiché dans la même réponse sans validation de la correspondance et avec une valeur provisoire : « Ironclassic → « Réalisation des workflows » *(si A)* ». |
| 2026-09-15 | T7 | Réussi | Fichier lu, une tâche Hugues / IronClassic / 17/09/2026, 3 étapes. Forme : préambule « Aucune tâche existante sur ce projet, donc aucun doublon. Voici l'aperçu : » et aperçu dans un bloc de code. |

Corrections apportées à `SKILL.md` entre les deux séries :

1. Questions : les déclencheurs deviennent une grille de cinq points à passer pour chaque tâche, avec un point « Contenu » (« voir pour le SEO » → « Que faut-il faire concrètement ? ») — T2, T5.
2. Déroulé étape 4 : forme de la réponse « aucune tâche » (raison par passage, arrêt) et interdiction de proposer une tâche de remplacement, avec la justification observée citée — T3.
3. Doublons lus avant les questions, dans chaque projet retenu ou candidat ; « Créer quand même ? » posé dès la première réponse (dans la liste de questions s'il y en a) — T4.
4. Autre destination étape 3 : gabarit de la réponse de correspondance, terminée par « Valider cette correspondance ? (oui / modifier) », aperçu après validation — T6.
5. Aperçu : la réponse commence par l'en-tête du tableau et se termine par « Valider ? … », Markdown rendu hors bloc de code — préambules et blocs de code de T1, T2, T7.

### Série 2 — `SKILL.md` corrigé

| Date | Cas | Verdict | Écarts restants |
|---|---|---|---|
| 2026-09-15 | T4 (relance 1) | Réussi | Doublon signalé : « Support Client : Analyse du message envoyé par Salma sur les améliorations à apporter » (To Do, Loup X Lotchi), « Créer quand même ? (oui / non) ». Projet demandé (Loup X Lotchi ou Lotchi Support Client), point 3 questionné, point 4 écarté, 21/09 et 16/09 sans question sur la référence. |
| 2026-09-15 | T4 (relance 2) | Réussi | Idem ; étapes de la tâche 2 annoncées : « reproduire → corriger → déployer en préproduction ». |
| 2026-09-15 | T2 (1er tour, relance 1) | Réussi | Question « Contenu : « voir pour le SEO » est trop vague… Que doit faire Martial concrètement ? » ajoutée aux autres. Forme : tâches désignées par A/B/C au lieu de numéros. |
| 2026-09-15 | T2 (2e tour, relance 1) | Réussi | Aperçu sans préambule ni bloc de code ; Martial / Site web Eurêka / 22/09/2026, Martial / Optimisation SEO des pages villes / 23/09/2026 ; pas de relance. |
| 2026-09-15 | T2 (1er tour, relance 2) | Réussi | Toutes les questions de l'Attendu, dont le contenu du SEO. |
| 2026-09-15 | T5 (relance 1) | Réussi | Refus en une phrase (« une valeur devinée […] écrirait des données fausses dans la base »), 7 questions dont le contenu du SEO, aucun aperçu. |
| 2026-09-15 | T3 (relance 1) | Réussi | « Aucune tâche à réaliser n'a été trouvée », raison par passage, aucune tâche suggérée. |
| 2026-09-15 | T3 (relance 2) | Réussi | Idem. |
| 2026-09-15 | T6 (relance 1) | Réussi | V2 `appegmTWYDaX5wKgi`, table Task, correspondance des six données (Projet : aucun champ direct, question sur le Module), « Valider cette correspondance ? (oui / modifier) », pas d'aperçu. |
| 2026-09-15 | T6 (relance 2) | Réussi | Idem. |
| 2026-09-15 | T5 (relance 2) | Réussi | Refus en une phrase (« les deviner fausserait la base »), 7 questions dont le contenu du SEO, aucun aperçu. |
| 2026-09-15 | T1 (non-régression) | Réussi | 2 tâches conformes, tâche proche signalée avec « Créer quand même ? (oui/non) », aperçu sans préambule ni bloc de code. Détail : ligne « Infos : Retour de Salma. » sans lien, contact ni référence (inutile mais tirée du texte). |

### Bilan

| Cas | Série 1 | Série 2 |
|---|---|---|
| T1 | Réussi (préambule) | Réussi |
| T2 1er tour | Échec | Réussi ×2 |
| T2 2e tour | Réussi (préambule, bloc de code) | Réussi |
| T3 | Échec (mineur) | Réussi ×2 |
| T4 | Échec | Réussi ×2 |
| T5 | Échec | Réussi ×2 |
| T6 | Échec | Réussi ×2 |
| T7 | Réussi (préambule, bloc de code) | non relancé |

Réserve sur T4 : l'Attendu donne le projet Loup X Lotchi comme acquis, mais la base contient deux projets actifs « Loup X Lotchi » (En cours) et « Lotchi Support Client » (En prod) pour un texte qui dit seulement « Lotchi » ; la question posée par le skill est celle qu'exige le §4 de la spec. `outils refusés` vide sur tous les lancements (outils d'écriture retirés par le banc).
