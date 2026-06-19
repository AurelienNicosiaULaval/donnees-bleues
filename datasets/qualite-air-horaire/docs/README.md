# Qualité de l'air au Québec

Source officielle : https://www.donneesquebec.ca/recherche/dataset/rsqaq-donnees-horaires-continues

Question d'analyse : Les concentrations de PM2.5 ont-elles augmenté durant certains épisodes particuliers?

Variables pédagogiques proposées : `date_heure`, `station`, `latitude`, `longitude`, `pm25`, `ozone`, `no2`, `so2`, `co`.

Notes : Les variables de contaminants doivent être harmonisées après inspection de la ressource annuelle retenue. Les coordonnées peuvent provenir du jeu RSQAQ des stations.

Les fichiers bruts ne sont pas redistribués par défaut. Déposer la ressource officielle retenue dans `data_raw/`, puis utiliser `preparation.R` pour produire une version préparée dans `data_processed/`.
