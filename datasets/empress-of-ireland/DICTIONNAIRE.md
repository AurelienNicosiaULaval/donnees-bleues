# Dictionnaire de la version pédagogique 1.0.0

Le jeu principal `empress_passengers.csv` contient 24 cellules de tableau qui représentent les 1 057 passagers selon le rapport final de l'enquête. Les effectifs sont regroupés; aucune ligne individuelle n'est reconstituée. Les 420 membres d'équipage figurent dans une table séparée.

| Variable | Type | Sens |
|---|---|---|
| `class` | Catégorie | `first`, `second`, `third` : classe des passagers. |
| `sex` | Catégorie | `male`, `female` : catégories inscrites dans le rapport historique. |
| `age_group` | Catégorie | `adult`, `child` : catégories historiques. Le seuil d'âge n'est pas établi par les pages retenues; aucun âge numérique n'est inventé. |
| `survived` | Entier | 1 pour les survivants, 0 pour les décès calculés dans le groupe. |
| `frequency` | Entier | Nombre de personnes dans cette cellule. Additionner cette variable pour compter les personnes. |
| `source_page` | Entier | Page imprimée du rapport final dans le volume numérisé : 610 ou 611. |
| `derivation` | Texte | Origine de l'effectif : compte de survivants imprimé, total moins survivants, points confirmés comme zéro par les totaux, ou zéro structurel confirmé à la question 1. |

Les quatre cellules d'effectif nul sont conservées. Les deux cellules des garçons de première classe sont des zéros structurels : aucune personne n'appartient à ce groupe dans le tableau du rapport. Sa proportion de survie est indéfinie, et non égale à zéro. Les deux autres cellules nulles correspondent à des groupes présents sans survivant indiqué dans ces tableaux complets.

`empress_passenger_groups.csv` présente les mêmes données en 12 groupes : `class`, `sex`, `age_group`, `total`, `survivors`, `deaths`, `source_page`. Chaque groupe vérifie `total = survivors + deaths`. Cette forme sert à une régression binomiale sur des comptes.

`empress_crew_groups.csv` contient six groupes : `crew_group`, `total`, `survivors`, `deaths`, `source_page`. Les groupes sont le pont (`deck`), la machine (`engine`), les mécaniciens surnuméraires (`supernumerary_engineers`), le service hôtelier hors les dix employées isolées par le tableau (`victualling_excluding_stewardesses`), la matron et les stewardesses (`matron_and_stewardesses`), et les musiciens (`musicians`). Aucune catégorie d'âge ou de sexe n'est attribuée aux autres groupes de l'équipage.

`empress_sources_comparison.csv` compare quatre listes nominatives NML aux comptes du rapport final : `source_id`, `passenger_class`, `listed_people`, `marked_survivors`, `unknown_status`, `inquiry_people`, `inquiry_survivors`. Les survivants marqués sont des preuves positives. Les personnes non marquées ne sont pas codées comme mortes.

Les fichiers de provenance suivants sont fournis dans la [trousse source 1.0.0](https://github.com/AurelienNicosiaULaval/empress-of-ireland-data/releases/tag/v1.0.0), accessible séparément de la trousse Données bleues. Les transcriptions des valeurs imprimées sont dans `references/inquiry_passenger_counts.csv` et `references/inquiry_crew_counts.csv`. Les points sont conservés comme `...` dans ces transcriptions. Les marges de contrôle de la question 1 sont dans `references/inquiry_q1_margins.csv`. Les pages 608, 610 et 611 sont fournies dans `references/inquiry_tables_excerpt.pdf`, respectivement aux pages PDF 1, 2 et 3. Les empreintes se trouvent dans `references/teaching_sources.json`.

Le fichier nominatif historique `empress_of_ireland.csv`, présent dans le dépôt de recherche, conserve un autre dictionnaire de 40 colonnes. Il ne fait pas partie de la trousse pédagogique. Il n'est ni joint aux tableaux regroupés, ni utilisé pour leur attribuer des noms ou des âges individuels.
