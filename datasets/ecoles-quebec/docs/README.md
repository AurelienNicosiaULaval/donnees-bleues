# Établissements scolaires du Québec

Source officielle : https://www.donneesquebec.ca/recherche/dataset/localisation-des-etablissements-d-enseignement-du-reseau-scolaire-au-quebec

Ressource retenue : CSV `Écoles publiques`.

Question d'analyse : comment cartographier les écoles publiques du Québec sans confondre une école, un immeuble et un lien école-immeuble?

Variables pédagogiques centrales : `CD_ORGNS`, `CD_IMM`, `ORDRE_ENS`, `TYPE_CS`, `NOM_REG_ADM`, `COORD_X_LL84_IMM`, `COORD_Y_LL84_IMM`, `lien_ecole_immeuble_id`, `longitude`, `latitude`.

Notes : une ligne représente un lien entre une école publique et un immeuble scolaire. Les comptes par région ne mesurent pas directement l'accès scolaire sans données complémentaires sur la population, les distances ou la capacité.

Les fichiers bruts ne sont pas redistribués par défaut. Exécuter `preparation.R` pour télécharger la ressource officielle dans `data/raw/ecoles-quebec/` et produire une version préparée dans `data/processed/ecoles-quebec/`.
