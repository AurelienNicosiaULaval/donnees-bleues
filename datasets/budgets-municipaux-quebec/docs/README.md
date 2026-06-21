# Profil financier des municipalités locales du Québec

Source officielle : https://www.donneesquebec.ca/recherche/dataset/profil-financier-des-municipalites-locales

API CKAN : https://www.donneesquebec.ca/recherche/api/3/action/package_show?id=profil-financier-des-municipalites-locales

Ressources préparées :

- `PF-2024-2025.csv`
- `PF-2024-2025-DescriptionPoste.csv`

Question d'analyse : comment les indicateurs de richesse foncière varient-ils selon la taille et la région des municipalités?

Exécuter depuis la racine du projet :

```r
source("datasets/budgets-municipaux-quebec/preparation.R")
```

Le script télécharge les fichiers officiels dans `data/raw/budgets-municipaux-quebec/` et écrit les tables préparées dans `data/processed/budgets-municipaux-quebec/`.

Fichiers préparés principaux :

- `profil_financier_municipalites_2025.csv`
- `profil_financier_municipalites_long_2025.csv`
- `dictionnaire_postes_profil_financier_2025.csv`
- `resume_classes_population_2025.csv`
- `resume_regions_profil_financier_2025.csv`
- `valeurs_manquantes_profil_financier_2025.csv`

Note importante : la ressource préparée provient du sommaire du rôle d'évaluation foncière 2025. Elle ne contient pas un budget municipal détaillé par postes de dépenses.
