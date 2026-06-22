# Construction, bâtiments et quartiers à la Ville de Québec

Documentation courte des fichiers préparés pour Données bleues.

## Sources officielles

Les données proviennent de trois jeux publiés par la Ville de Québec dans Données Québec, tous déclarés sous licence Attribution (CC-BY 4.0) dans les métadonnées CKAN consultées le 2026-06-21.

| Fichier préparé | Source officielle | URL |
|---|---|---|
| `permis_delivres_quebec.csv` | Permis délivrés à la Ville de Québec | <https://www.donneesquebec.ca/recherche/dataset/permis-delivres-ville-de-quebec> |
| `batiments_quebec.csv` | Empreintes des bâtiments | <https://www.donneesquebec.ca/recherche/dataset/empreintes-des-batiments> |
| `quartiers_quebec.csv` | Quartiers | <https://www.donneesquebec.ca/recherche/dataset/vque_9> |
| `quebec_construction_quartiers.csv` | Agrégat dérivé des trois sources précédentes | Source dérivée locale, script `preparation.R` |

Date de téléchargement locale utilisée pour cette intégration : 2026-06-21.

## Fichiers produits

Les fichiers CSV préparés sont écrits par `preparation.R` dans `data/processed/construction-quartiers-quebec/`.

- `permis_delivres_quebec.csv` contient les colonnes officielles du CSV des permis avec noms nettoyés.
- `batiments_quebec.csv` contient les colonnes officielles du CSV des empreintes avec noms nettoyés.
- `quartiers_quebec.csv` contient les colonnes officielles du CSV des quartiers avec noms nettoyés.
- `quebec_construction_quartiers.csv` contient une ligne par quartier officiel et des indicateurs agrégés construits par jointure spatiale.
- `documentation_sources.csv` résume les sources, licences, ressources CKAN et dates de téléchargement.
- `dictionnaire_variables.csv` décrit les variables des fichiers préparés.
- `appariement_quartiers_resume.csv` indique combien de permis et de bâtiments ont pu être appariés aux quartiers officiels.

## Informations non disponibles dans les sources utilisées

- Le fichier des permis ne contient pas la valeur monétaire des travaux.
- Le fichier des permis ne contient pas la superficie des travaux.
- Le fichier des permis ne contient pas directement le quartier.
- Le fichier des empreintes de bâtiments ne contient pas la hauteur, le nombre d'étages, l'année de construction ou l'usage détaillé.
- Le fichier des quartiers ne contient pas la population, le nombre de logements ou le zonage.

Ces variables ne sont donc pas créées dans l'agrégat.

## Principe de l'agrégat par quartier

Les permis sont appariés aux quartiers à partir de leurs coordonnées longitude et latitude.

Les empreintes de bâtiments sont appariées aux quartiers à partir d'un point représentatif situé sur chaque polygone de bâtiment. Cette règle évite de compter deux fois un bâtiment qui chevauche une limite de quartier.

Les superficies des empreintes de bâtiments sont calculées à partir des géométries officielles projetées en EPSG:32187, projection mentionnée dans les métadonnées officielles des quartiers pour les superficies et périmètres approximatifs.

Les objets qui ne tombent dans aucun quartier officiel ne sont pas forcés dans un quartier. Leur nombre est documenté dans `appariement_quartiers_resume.csv`.
