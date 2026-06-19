# Emploi régional au Québec

Source officielle : https://statistique.quebec.ca/fr/document/population-active-emploi-et-chomage-regions-administratives-rmr-et-quebec

Question d'analyse : Comment l'emploi varie-t-il selon les régions administratives?

Variables pédagogiques proposées : `region`, `annee`, `mois`, `taux_chomage`, `taux_emploi`, `population_active`.

Notes : La page de Statistique Québec diffuse les indicateurs de l'EPA par région administrative. Les données proviennent de Statistique Canada.

Les fichiers bruts ne sont pas redistribués par défaut. Déposer la ressource officielle retenue dans `data_raw/`, puis utiliser `preparation.R` pour produire une version préparée dans `data_processed/`.
