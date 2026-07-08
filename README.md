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

## Dans l’écosystème de recherche et d’enseignement

Ce dépôt fait partie de l’écosystème ouvert d’Aurélien Nicosia en statistique computationnelle, logiciels scientifiques en R, science des données reproductible et pédagogie statistique.

* Research Lab : [https://aureliennicosiaulaval.github.io/web_site/research-lab.html](https://aureliennicosiaulaval.github.io/web_site/research-lab.html)
* Profil GitHub : [https://github.com/AurelienNicosiaULaval](https://github.com/AurelienNicosiaULaval)
* Projets reliés : [`STT-1100_notes_de_cours`](https://github.com/AurelienNicosiaULaval/STT-1100_notes_de_cours), [`UlavalSSD`](https://github.com/AurelienNicosiaULaval/UlavalSSD), [`tutorizeR`](https://github.com/AurelienNicosiaULaval/tutorizeR)

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

Le catalogue public est la source à jour pour l'inventaire des jeux de données et des activités pédagogiques :

- Catalogue public : [https://aureliennicosiaulaval.github.io/donnees-bleues/catalogue.html](https://aureliennicosiaulaval.github.io/donnees-bleues/catalogue.html)
- Catalogue généré : [`data/metadata/catalogue.csv`](data/metadata/catalogue.csv)
- Catalogue des activités : [`data/metadata/catalogue_activites.csv`](data/metadata/catalogue_activites.csv)

Ces catalogues remplacent la liste statique du README et doivent être considérés comme les inventaires de référence.

## Attribution et réutilisation

Chaque jeu de données est documenté avec sa source originale, son URL, sa licence ou ses conditions de réutilisation lorsqu'elles sont disponibles, sa date d'accès et des notes de prudence.

La plateforme Données bleues vise à faciliter l'enseignement de la statistique et de la science des données à partir de données québécoises ouvertes ou publiquement accessibles. Elle ne remplace pas les sources originales.

Pour réutiliser un jeu de données, il faut toujours consulter la fiche correspondante et respecter les conditions de la source originale.

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
- un catalogue généré qui présente l'inventaire à jour des jeux de données et des activités pédagogiques;
- des fiches de jeux de données québécois ou canadiens avec un usage québécois explicite;
- un catalogue d'activités indexé par question, niveau, type, concept, contexte et accroche;
- trois modules transversaux;
- des scripts R de préparation;
- des fonctions utilitaires CKAN, catalogue et zero waste dataset;
- des modèles réutilisables;
- une documentation de publication.

## Éléments à compléter manuellement

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
