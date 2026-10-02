# ggplot builder | Données bleues

Un atelier en français pour construire un graphique avec les 200 arbres du
Québec du jeu pédagogique v1.0.0. Cinq étapes relient les réglages au code :
données, géométrie, couleurs, couches et finition.

[Ouvrir le builder](https://donneesbleues.ca/outils/ggplot-builder/).
La version en ligne exécute R dans le navigateur avec Shinylive. Le premier
chargement télécharge le moteur et les bibliothèques nécessaires. Le CSV est
inclus; aucune acquisition de nouvelles données n’est requise.

## Lancement local

Décompresser l’application et ouvrir son dossier dans RStudio. Exécuter
`INSTALLER.R` si un package manque, puis `LANCER.R`.

```r
library(shiny)
runApp(".")
```

Packages requis : shiny, bslib, ggplot2, dplyr et readr.

## Utilisation

Choisir un point de départ : portrait forestier, diamètre-hauteur ou
distributions. « Partir de zéro » revient à la première étape. Les réglages
des étapes suivantes restent mémorisés et apparaissent lorsqu’on atteint
l’étape correspondante. Le sélecteur propose des points, des boîtes, des
violons, des densités et des histogrammes.

Le graphique et le code affiché utilisent la même génération. Le script R
téléchargeable inclut les bibliothèques et l’importation du CSV versionné;
son exécution nécessite Internet. Le CSV téléchargeable conserve les 200
arbres et les 21 colonnes de la source. La dispersion des points a une graine
fixe. Sur écran étroit, le code reflète l’adaptation du texte et des titres.

## Données et limites

MRNF / PET5, sélection pédagogique d’Aurélien Nicosia (2026),
[Arbres du Québec v1.0.0](https://github.com/AurelienNicosiaULaval/arbres_quebec/releases/tag/v1.0.0).
Chaque arbre provient d’une placette distincte. Les 50 arbres par espèce sont
imposés par la sélection; la représentativité provinciale n’est pas établie.
L’âge manque pour 52 arbres, dont tous les érables rouges. Seules les lignes
sans les mesures nécessaires sont exclues et leur nombre est indiqué.
Aucune imputation n’est réalisée. La surface terrière, dérivée du diamètre,
n’est pas proposée comme une troisième mesure morphologique indépendante.

Les densités ont une largeur de bande automatique. La droite est descriptive,
sans interprétation causale. Les graphiques décrivent les arbres retenus.

Données et adaptations : CC BY 4.0; taxonomie VASCAN : CC0 1.0.
Code original : MIT; contenus pédagogiques : CC BY 4.0.
Voir `DATA_LICENSES.md`, `LICENSE` et `LICENCE-CONTENUS.md`.

## Vérification

Dans le dossier de l’application, `Rscript verifier.R` vérifie les données,
150 configurations, les formats étroits, les âges manquants, les sélections
vides et la reproduction par le script exporté. Ce contrôle complet importe
également le CSV versionné et nécessite Internet.

Environnement local vérifié : R 4.5.0, shiny 1.14.0, bslib 0.12.0,
ggplot2 4.0.2, dplyr 1.2.1, readr 2.1.5. L’usage en classe n’est pas documenté.

Le parcours est inspiré du
[tutoriel Évolution d’un ggplot](https://aureliennicosia.shinyapps.io/TutorielGGplot/)
d’Aurélien Nicosia. Cette application n’exécute pas du code R libre saisi par
l’utilisateur dans le navigateur.
