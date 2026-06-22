# Données bleues

Données bleues est un MVP de plateforme pédagogique ouverte qui valorise des jeux de données québécois pour l'enseignement de la statistique, de la programmation R et de la science des données.

Le message éditorial du projet est le suivant : un jeu de données n'est pas seulement une table. C'est un territoire d'apprentissage.

## Objectifs

- Rassembler des jeux de données québécois vérifiés.
- Fournir des fiches pédagogiques prêtes à utiliser.
- Proposer des activités courtes et longues.
- Documenter les sources, licences et limites.
- Favoriser des workflows reproductibles avec R et Quarto.
- Préparer une architecture compatible avec une future application Shiny ou un package R.

## Structure du dépôt

```text
.
├── README.md
├── _quarto.yml
├── index.qmd
├── about.qmd
├── activites.qmd
├── catalogue.qmd
├── contribuer.qmd
├── references.qmd
├── zero-waste.qmd
├── styles.css
├── R/
├── scripts/
├── datasets/
├── activities/
├── templates/
├── data/
├── app/
└── docs/
```

## Jeux de données inclus

Les sources initiales ont été vérifiées le 2026-06-01. La source Statistique Canada ajoutée pour les pyramides des âges a été vérifiée le 2026-06-18. Les sources de la Ville de Québec ajoutées pour la construction, les bâtiments et les quartiers ont été vérifiées le 2026-06-21.

| Dossier | Jeu de données | Source |
|---|---|---|
| `datasets/bixi` | État des stations BIXI | BIXI Montréal, Données Québec |
| `datasets/bibliotheques-quebec` | Statistiques des bibliothèques publiques du Québec | Bibliothèque et Archives nationales du Québec, Données Québec |
| `datasets/construction-quartiers-quebec` | Construction, bâtiments et quartiers à la Ville de Québec | Ville de Québec, Données Québec |
| `datasets/pyramides-ages` | Pyramides des âges au Canada et au Québec | Statistique Canada |
| `datasets/qualite-air` | RSQAQ - Stations de la qualité de l'air | MELCCFP, Données Québec |

## Installation minimale

Installer Quarto et R. Les packages R utilisés par le MVP sont :

```r
install.packages(c(
  "cansim",
  "dplyr",
  "ggplot2",
  "httr2",
  "janitor",
  "jsonlite",
  "knitr",
  "lubridate",
  "purrr",
  "readr",
  "sf",
  "stringr",
  "tidyr",
  "yaml"
))
```

## Construire le catalogue

Le catalogue des jeux de données est généré à partir des fichiers `metadata.yml`.

```bash
Rscript scripts/build_catalogue.R
```

Cette commande produit :

```text
data/metadata/catalogue.csv
data/metadata/catalogue.rds
```

Elle vérifie aussi qu'une vraie vignette existe dans `assets/cards/` pour chaque jeu de données. Les vignettes Wikimedia Commons sont déclarées et générées par `scripts/generate_card_images.R`.

Le catalogue des activités est généré à partir des fichiers `activite-*.yml`.

```bash
Rscript scripts/build_activity_catalogue.R
```

Cette commande produit :

```text
data/metadata/catalogue_activites.csv
data/metadata/catalogue_activites.rds
```

## Vérifier les fiches

```bash
Rscript scripts/check_datasets.R
```

La vérification contrôle la présence des fichiers obligatoires, les champs des métadonnées, les scores zero waste dataset et les métadonnées des activités.

## Préparer les données

Les scripts de préparation peuvent être lancés depuis la racine du projet :

```bash
Rscript datasets/bixi/preparation.R
Rscript datasets/bibliotheques-quebec/preparation.R
Rscript datasets/construction-quartiers-quebec/preparation.R
Rscript datasets/pyramides-ages/preparation.R
Rscript datasets/qualite-air/preparation.R
```

Les fichiers téléchargés ou préparés sont écrits dans `data/raw/` et `data/processed/`. Ces dossiers sont ignorés par Git, sauf les fichiers `.gitkeep`.

## Données institutionnelles ULaval

L'intégration ULaval utilise comme source canonique le dépôt privé :

```text
git@github.com:AurelienNicosiaULaval/donnees-ulaval-institutionnelles.git
```

Les CSV institutionnels et les PDF sources ne sont pas versionnés dans Données bleues. Cloner la source privée dans un dossier ignoré :

```bash
mkdir -p .private
git clone git@github.com:AurelienNicosiaULaval/donnees-ulaval-institutionnelles.git .private/donnees-ulaval-institutionnelles
```

Valider l'intégration depuis la source privée :

```bash
Rscript scripts/validate_ulaval_integration.R --phase=core,ges
```

Importer localement les trois fichiers prioritaires, sans les publier :

```bash
Rscript scripts/import_ulaval_institutional_data.R --phase=core
```

Les copies locales sont écrites dans `data/processed/ulaval/`, qui est ignoré par Git. Cette intégration est une compilation indépendante et non officielle; elle n'est pas un produit officiel ou approuvé par l'Université Laval. Aucune licence ouverte explicite n'a été identifiée pour les données sources dans le paquet consulté le 2026-06-19.

## Rendre le site

```bash
quarto render
```

ou :

```bash
Rscript scripts/render_site.R
```

Le site généré est placé dans `docs/`.

## Publication GitHub Pages

Option A, recommandée pour le MVP :

1. Rendre le site localement avec `quarto render`.
2. Pousser le dépôt sur GitHub.
3. Dans les paramètres GitHub Pages du dépôt, choisir la branche principale et le dossier `/docs`.

Option B, à ajouter plus tard :

Créer un workflow GitHub Actions qui installe R, installe les packages, génère le catalogue et rend le site automatiquement. Cette option est utile lorsque le projet contient plus de jeux de données ou des dépendances plus lourdes.

## Ajouter un jeu de données

1. Créer un dossier dans `datasets/`.
2. Copier les modèles depuis `templates/`.
3. Remplir `metadata.yml`.
4. Rédiger `fiche.qmd`.
5. Ajouter `activite-courte.qmd` et `activite-longue.qmd`.
6. Ajouter `activite-courte.yml` et `activite-longue.yml`.
7. Écrire `preparation.R`.
8. Exécuter :

```bash
Rscript scripts/check_datasets.R
Rscript scripts/build_catalogue.R
Rscript scripts/build_activity_catalogue.R
quarto render
```

## Statut du MVP

Le MVP contient :

- un site Quarto publiable depuis `docs/`;
- une identité éditoriale en français;
- plusieurs fiches de jeux de données québécois ou canadiens avec un usage québécois explicite;
- huit activités pédagogiques;
- un catalogue d'activités indexé par question, niveau, type, concept, contexte et accroche;
- trois modules transversaux;
- des scripts R de préparation;
- des fonctions utilitaires CKAN, catalogue et zero waste dataset;
- des modèles réutilisables;
- une documentation de publication.

## Éléments à compléter manuellement

- Remplacer `site-url` dans `_quarto.yml` par l'URL GitHub Pages réelle.
- Tester les activités avec un groupe étudiant.
- Ajouter des corrigés enseignants si nécessaire.
- Vérifier périodiquement les URL et les licences.
- Décider si un fichier `renv.lock` est nécessaire.

## Prochaines étapes possibles

- Ajouter 10 jeux de données.
- Créer une application Shiny de filtrage.
- Créer un package R `donneesbleues`.
- Ajouter des badges de niveau.
- Ajouter une interface de contribution.
- Ajouter des corrigés enseignants.
- Ajouter des activités Quarto ou learnr.
- Ajouter un filtre interactif pour chercher une activité par concept, niveau, durée ou accroche.
- Ajouter une version anglaise éventuellement.
- Ajouter une API ou un script de moissonnage Données Québec.
