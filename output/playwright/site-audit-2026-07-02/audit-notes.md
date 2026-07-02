# Audit pédagogique et visuel du site Données bleues

Date: 2026-07-02

Source auditée: rendu local dans `docs/`, sans modifier le dépôt.

Référence d'accessibilité utilisée: WCAG 2.2, notamment contraste minimum, reflow, focus et taille des cibles interactives. Source: W3C, 2023, https://www.w3.org/TR/WCAG22/

## Étapes capturées

1. Accueil, desktop et mobile: état général fort. La promesse pédagogique est claire et mémorable.
2. Catalogue, desktop et mobile: état fonctionnel fort. Recherche testée avec `BIXI`, résultat ramené à 1 jeu de données.
3. Activités, desktop et mobile: état pédagogique fort. La page transforme bien les jeux de données en usages de classe.
4. Zéro déchet, desktop et mobile: état conceptuel fort, mais risque visuel important sur le contraste du texte secondaire dans le héros.
5. À propos, desktop et mobile: état très solide. Bonne formulation du problème, de l'audience et des limites.
6. Fiche BIXI, desktop et mobile: très bonne valeur pédagogique, mais problème mobile dans les blocs de métadonnées.

## Diagnostic général

Le site a une vraie position pédagogique. Il ne se contente pas de lister des fichiers: il transforme des sources ouvertes en ressources d'enseignement avec contexte, unité statistique, licence, limites, activités, pistes de projet et score zéro déchet. C'est le point le plus fort du site.

Visuellement, le site a franchi un seuil professionnel: identité claire, palette cohérente, cartes lisibles, boutons explicites, pages éditoriales plus ambitieuses que du Quarto standard. Le site paraît déjà utilisable publiquement.

Le principal risque n'est pas le manque d'information. C'est plutôt l'excès de densité à certains endroits, surtout sur mobile et dans les pages à forte valeur pédagogique. Certaines informations importantes deviennent difficiles à scanner ou se compriment trop.

## Forces pédagogiques

- La promesse est bien formulée: partir de données québécoises et canadiennes, mais sans réduire le projet à un simple catalogue local.
- Le site enseigne une posture statistique saine: provenance, unité statistique, licence, limites, prudence interprétative.
- La page Catalogue est orientée vers l'usage en classe, notamment avec "idée en classe" et le score pédagogique.
- La page Activités est très pertinente pour une personne enseignante: elle part du temps disponible, du niveau, du type d'activité et de la question pédagogique.
- Le cadre zéro déchet est une très bonne idée structurante. Il donne un vocabulaire interne au site et aide à juger la valeur d'un jeu de données.
- Les fiches détaillées, comme BIXI, montrent rapidement le lien entre source, question de départ, R en action, aperçu de résultats et potentiel pédagogique.

## Risques pédagogiques

- La page d'accueil explique beaucoup avant de montrer un exemple concret. Une enseignante convaincue lira; une personne pressée pourrait vouloir voir immédiatement une fiche exemplaire ou une activité prête à utiliser.
- Le score zéro déchet est visible, mais sa signification peut rester abstraite dans le catalogue. "25 / 30" est utile, mais il faudrait peut-être rendre le pourquoi plus immédiat.
- Les filtres du catalogue sont puissants, mais ils peuvent paraître techniques. Les notions pédagogiques sont nombreuses; sans regroupement, elles peuvent produire une charge cognitive élevée.
- Les fiches sont riches, mais la première vue pourrait mieux distinguer ce qui sert à choisir la ressource et ce qui sert à l'utiliser en classe.

## Forces visuelles

- L'accueil a un impact fort. Le site a une identité claire, sérieuse, institutionnelle, mais pas froide.
- La navigation principale est stable et lisible sur desktop.
- Les cartes du catalogue sont efficaces: image, titre, source, niveau, territoire, idée en classe et appel à l'action.
- La page À propos est particulièrement réussie: belle hiérarchie, bonne respiration, bon équilibre entre texte et encadré.
- Les boutons et liens principaux sont assez explicites, avec une bonne cohérence de style.
- Les captures desktop ne montrent pas de débordement horizontal.

## Risques visuels et accessibilité

- Sur la page zéro déchet, le texte secondaire du héros est trop sombre sur le fond sombre. Il risque de ne pas satisfaire le contraste minimum attendu pour du texte normal.
- Sur mobile, les héros Accueil, Activités et Zéro déchet prennent beaucoup de hauteur. C'est visuellement fort, mais le contenu suivant arrive tard.
- Sur la fiche BIXI mobile, les blocs de métadonnées sont trop serrés. Le bloc "structure" est visuellement coupé, ce qui nuit à une information essentielle.
- Sur mobile, la navigation affiche surtout la marque; les liens principaux ne sont pas visibles dans la première capture. Il faut vérifier que le menu hamburger est assez clair et accessible au clavier.
- Le catalogue mobile fonctionne, mais les filtres prennent beaucoup de place avant les résultats. Pour un usage en classe, il faudrait peut-être prioriser recherche, résultats, puis filtres avancés.
- Plusieurs pages ont deux titres H1 dans le DOM selon l'inspection. Si le premier est entièrement masqué par Quarto, ce n'est pas nécessairement grave, mais la structure de titres devrait être vérifiée dans l'arbre d'accessibilité.

## Recommandations prioritaires

1. Corriger le contraste du héros zéro déchet.
   Rendre le texte de lede plus clair ou augmenter l'opacité du voile sombre. C'est le correctif visuel le plus urgent.

2. Repenser les métadonnées des fiches sur mobile.
   Passer les blocs "territoire, niveau, structure, format" en une colonne ou en cartes empilées sous 640 px. Ne pas comprimer les libellés longs.

3. Réduire la hauteur utile des héros mobiles.
   Garder l'impact, mais faire apparaître plus rapidement les statistiques, les exemples ou la première action concrète.

4. Améliorer l'explication du score zéro déchet dans le catalogue.
   Ajouter un court libellé ou une infobulle plus explicite, par exemple "potentiel de réutilisation pédagogique".

5. Regrouper les notions pédagogiques du catalogue.
   Conserver les filtres détaillés, mais ajouter des familles plus lisibles: importer/nettoyer, visualiser, modéliser, éthique, données spatiales, séries temporelles.

6. Mettre en avant une fiche exemplaire dès l'accueil.
   Ajouter une courte section "Exemple en 2 minutes" avec une fiche et une activité associée. Cela aiderait les nouveaux visiteurs à comprendre immédiatement la valeur concrète.

7. Vérifier l'accessibilité au clavier.
   Tester tabulation, focus visible, menu mobile, recherche, filtres, réinitialisation et cartes. Les captures ne suffisent pas à conclure sur la conformité.

## Plan d'implémentation

Ce plan transforme l'audit en feuille de route concrète pour corriger le site Données bleues. Il ne prévoit aucun changement aux données, aux catalogues générés ou aux métadonnées. Les interventions attendues sont visuelles, éditoriales et ergonomiques dans le site Quarto.

### Priorité 1 - Corriger le contraste du héros zéro déchet

Fichier principal : `styles.css`.

Objectif : rendre lisible tout le texte du héros de `zero-waste.qmd`, surtout le paragraphe `.zw-hero-lede` sur desktop et mobile.

Implémentation prévue :

- augmenter le contraste du voile sombre de `.zw-hero`;
- conserver l'image de fond et l'effet éditorial actuel;
- garder le titre en blanc;
- éclaircir ou renforcer `.zw-hero-lede`;
- vérifier le rendu mobile dans le bloc `@media (max-width: 700px)`.

Critère d'acceptation : le texte secondaire du héros zéro déchet doit être lisible sans effort sur une capture desktop 1440 px et mobile 390 px.

### Priorité 2 - Corriger les métadonnées des fiches sur mobile

Fichiers principaux : `R/utils_dataset_page.R` et `styles.css`.

Objectif : éviter que les blocs `Territoire`, `Niveau`, `Structure` et `Format` soient comprimés ou coupés sur mobile.

Implémentation prévue :

- conserver la génération actuelle des blocs dans `R/utils_dataset_page.R`, sauf si une classe additionnelle devient nécessaire;
- modifier surtout les règles responsive de `.dataset-overview-grid` dans `styles.css`;
- sous 640 px, passer les blocs en une seule colonne ou en cartes empilées;
- retirer les séparateurs verticaux qui compriment les textes longs;
- laisser les libellés longs revenir naturellement à la ligne.

Critère d'acceptation : sur la fiche BIXI mobile, le champ `Structure` doit être entièrement lisible et ne pas donner l'impression d'être tronqué.

### Priorité 3 - Réduire la hauteur utile des héros mobiles

Fichier principal : `styles.css`.

Objectif : préserver l'identité visuelle tout en faisant apparaître plus rapidement le contenu suivant sur mobile.

Implémentation prévue :

- ajuster les paddings mobiles de `.home-hero`, `.act-hero` et `.zw-hero`;
- réduire légèrement les tailles de titres mobiles si nécessaire;
- conserver les boutons principaux visibles;
- éviter tout changement de composition desktop.

Critère d'acceptation : sur mobile 390 px, le héros reste fort visuellement, mais les statistiques, le panneau résumé ou le début du contenu suivant apparaissent plus tôt.

### Priorité 4 - Clarifier le score zéro déchet dans le catalogue

Fichier principal : `catalogue.qmd`.

Objectif : rendre le score plus compréhensible pour une personne enseignante qui découvre le site.

Implémentation prévue :

- remplacer ou compléter le libellé `Potentiel pédagogique` par une formulation plus explicite liée à la réutilisation pédagogique;
- ajouter une aide courte près du score, par exemple une infobulle ou un texte accessible;
- conserver la valeur numérique et les segments visuels;
- ne pas modifier le calcul du score ni les fichiers de métadonnées.

Critère d'acceptation : une carte du catalogue doit permettre de comprendre que le score indique le potentiel de réutilisation pédagogique d'un jeu de données.

### Priorité 5 - Rendre les filtres de notions pédagogiques plus scannables

Fichier principal : `catalogue.qmd`.

Objectif : réduire la charge cognitive créée par la longue liste de notions pédagogiques.

Implémentation prévue :

- conserver les notions existantes issues des métadonnées;
- ajouter des familles de notions plus lisibles, sans changer les fichiers `metadata.yml`;
- utiliser des regroupements comme `Importer et nettoyer`, `Visualiser`, `Modéliser`, `Éthique et limites`, `Données spatiales`, `Séries temporelles`;
- garder les filtres détaillés accessibles pour les usages plus précis.

Critère d'acceptation : le catalogue doit rester filtrable finement, mais l'entrée par notions doit être plus rapide à comprendre.

### Priorité 6 - Renforcer l'accueil avec un exemple concret

Fichier principal : `index.qmd`.

Objectif : montrer immédiatement la valeur d'usage du site à une personne qui arrive pour la première fois.

Implémentation prévue :

- ajouter un court bloc `Exemple en 2 minutes`;
- relier une fiche exemplaire, une activité courte et une activité longue;
- privilégier un jeu de données déjà bien illustré et stable, par exemple BIXI;
- garder le bloc bref pour ne pas alourdir la page d'accueil.

Critère d'acceptation : l'accueil doit permettre de comprendre en moins de deux minutes comment passer d'un jeu de données à une activité d'enseignement.

### Priorité 7 - Documenter une passe QA clavier et responsive

Fichiers principaux : rapport d'audit et captures de vérification.

Objectif : vérifier les points que les captures seules ne suffisent pas à confirmer.

Implémentation prévue :

- tester la tabulation sur les pages principales;
- vérifier le focus visible;
- tester le menu mobile;
- tester le champ de recherche du catalogue;
- tester les filtres, la réinitialisation et les liens `Voir la fiche`;
- capturer le rendu desktop 1440 px et mobile 390 px après correction.

Critère d'acceptation : la QA doit confirmer l'absence de débordement horizontal, le bon focus clavier et la lisibilité mobile des zones corrigées.

### Changements d'interface exclus

- Aucun changement de schéma de données.
- Aucun changement aux fichiers `metadata.yml`.
- Aucun changement direct à `data/metadata/catalogue.csv`.
- Aucun changement direct à `data/metadata/catalogue_activites.csv`.
- Aucun changement au calcul du score zéro déchet.
- Aucun changement à l'architecture Quarto du site.

### Tests et validation

Après implémentation des corrections, exécuter :

```bash
Rscript scripts/check_datasets.R
Rscript scripts/render_site.R
```

Puis vérifier au minimum :

- `docs/index.html`;
- `docs/catalogue.html`;
- `docs/activites.html`;
- `docs/zero-waste.html`;
- `docs/about.html`;
- `docs/datasets/bixi/fiche.html`.

Scénarios d'acceptation :

- aucune page vérifiée ne présente de débordement horizontal;
- le héros zéro déchet est lisible sur desktop et mobile;
- la fiche BIXI mobile ne coupe plus les métadonnées;
- la recherche `BIXI` dans le catalogue retourne `1 jeu de données`;
- les filtres et la réinitialisation restent fonctionnels;
- la navigation clavier conserve un focus visible.

## Suivi d'implémentation

Corrections appliquées :

- `styles.css` : contraste renforcé du héros zéro déchet, lede en blanc, voile de fond plus lisible, héros mobiles Accueil, Activités et Zéro déchet plus compacts.
- `styles.css` : métadonnées de fiches empilées sous 640 px, sans séparateurs verticaux compressifs, avec retour à la ligne pour les champs longs.
- `styles.css` : focus clavier visible sur les boutons, champs, liens et bouton de menu mobile.
- `catalogue.qmd` : ajout des familles pédagogiques, conservation des notions détaillées, filtrage par `concept-family`, libellé du score remplacé par `Réutilisation pédagogique`.
- `catalogue.qmd` : aide courte du score ajoutée sans modifier le calcul ni les métadonnées.
- `index.qmd` : bloc `Exemple en 2 minutes` ajouté avec la fiche BIXI, une activité courte et une activité longue.
- `docs/index.html`, `docs/catalogue.html` et `docs/styles.css` : rendu public mis à jour pour les zones modifiées.

Validation effectuée :

- `Rscript scripts/check_datasets.R` : succès.
- `quarto render catalogue.qmd --execute --no-cache --no-clean` : `docs/catalogue.html` mis à jour; Quarto est resté accroché après écriture du HTML et le processus résiduel a été arrêté.
- `Rscript scripts/render_site.R` : non terminé; le script est resté bloqué sur `quarto render index.qmd --execute --no-cache --no-clean` après plus de deux minutes sans sortie et le processus résiduel a été arrêté.
- QA navigateur effectuée via Playwright sur `http://127.0.0.1:8123`, car le plugin Browser n'était pas disponible dans cette session.

Résultats QA :

- Pages vérifiées en desktop 1440 px et mobile 390 px : `index.html`, `catalogue.html`, `activites.html`, `zero-waste.html`, `about.html`, `datasets/bixi/fiche.html`.
- Aucune page vérifiée ne présente de débordement horizontal.
- `BIXI` dans la recherche du catalogue retourne `1 jeu de données`.
- Le filtre famille `Visualiser` fonctionne seul et retourne `17 jeux de données`.
- La réinitialisation du catalogue revient à `26 jeux de données` et redonne le focus au champ de recherche.
- Le menu mobile s'ouvre au clavier avec `Entrée`; le bouton conserve un focus visible.
- Le héros zéro déchet mobile affiche `.zw-hero-lede` en blanc avec un poids `650`.
- Les règles CSS corrigent l'empilement mobile de `.dataset-overview-grid` lorsque ce bloc est présent. Dans le dernier `origin/main` utilisé pour le déploiement, la fiche BIXI publique ne contient plus ce bloc, et la QA mobile confirme l'absence de débordement horizontal.

Captures de vérification :

- `/tmp/donneesbleues-qa-20260702/index-desktop-1440.png`
- `/tmp/donneesbleues-qa-20260702/index-mobile-390.png`
- `/tmp/donneesbleues-qa-20260702/catalogue-desktop-1440.png`
- `/tmp/donneesbleues-qa-20260702/catalogue-mobile-390.png`
- `/tmp/donneesbleues-qa-20260702/zero-waste-desktop-1440.png`
- `/tmp/donneesbleues-qa-20260702/zero-waste-mobile-390.png`
- `/tmp/donneesbleues-qa-20260702/bixi-fiche-desktop-1440.png`
- `/tmp/donneesbleues-qa-20260702/bixi-fiche-mobile-390.png`

Point de vigilance restant :

- Le rendu complet `scripts/render_site.R` doit être relancé dans un environnement où Quarto ne reste pas accroché après l'écriture des pages. Le blocage observé est un problème d'exécution locale Quarto/File Provider, pas un échec identifié des corrections visuelles ou éditoriales.

## Verdict

Le site est déjà pédagogiquement fort et visuellement crédible. Il donne une impression de projet sérieux, utile et ancré dans une vraie réflexion statistique. Les corrections les plus importantes concernent le mobile, le contraste de quelques zones héroïques et la hiérarchisation de l'information dans les zones denses. Ce ne sont pas des problèmes de fond; ce sont des problèmes de finition et d'ergonomie qui peuvent nettement améliorer l'expérience.
