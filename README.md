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

Les sources ont été vérifiées le 2026-06-01.

| Dossier | Jeu de données | Source |
|---|---|---|
| `datasets/bixi` | État des stations BIXI | BIXI Montréal, Données Québec |
| `datasets/bibliotheques-quebec` | Statistiques des bibliothèques publiques du Québec | Bibliothèque et Archives nationales du Québec, Données Québec |
| `datasets/qualite-air` | RSQAQ - Stations de la qualité de l'air | MELCCFP, Données Québec |

## Installation minimale

Installer Quarto et R. Les packages R utilisés par le MVP sont :

```r
install.packages(c(
  "dplyr",
  "ggplot2",
  "httr2",
  "jsonlite",
  "knitr",
  "lubridate",
  "purrr",
  "readr",
  "stringr",
  "tidyr",
  "yaml"
))
```

## Construire le catalogue

Le catalogue est généré à partir des fichiers `metadata.yml`.

```bash
Rscript scripts/build_catalogue.R
```

Cette commande produit :

```text
data/metadata/catalogue.csv
data/metadata/catalogue.rds
```

## Vérifier les fiches

```bash
Rscript scripts/check_datasets.R
```

La vérification contrôle la présence des fichiers obligatoires, les champs des métadonnées et les scores zero waste dataset.

## Préparer les données

Les scripts de préparation peuvent être lancés depuis la racine du projet :

```bash
Rscript datasets/bixi/preparation.R
Rscript datasets/bibliotheques-quebec/preparation.R
Rscript datasets/qualite-air/preparation.R
```

Les fichiers téléchargés ou préparés sont écrits dans `data/raw/` et `data/processed/`. Ces dossiers sont ignorés par Git, sauf les fichiers `.gitkeep`.

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
6. Écrire `preparation.R`.
7. Exécuter :

```bash
Rscript scripts/check_datasets.R
Rscript scripts/build_catalogue.R
quarto render
```

## Statut du MVP

Le MVP contient :

- un site Quarto publiable depuis `docs/`;
- une identité éditoriale en français;
- trois fiches de jeux de données québécois;
- six activités pédagogiques;
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
- Ajouter une version anglaise éventuellement.
- Ajouter une API ou un script de moissonnage Données Québec.

