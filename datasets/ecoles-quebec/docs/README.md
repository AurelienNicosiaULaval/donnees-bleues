# Établissements scolaires du Québec

Source officielle : https://www.donneesquebec.ca/recherche/dataset/localisation-des-etablissements-d-enseignement-du-reseau-scolaire-au-quebec

Question d'analyse : Où sont localisées les écoles du Québec et quelles régions sont les plus densément desservies?

Variables pédagogiques proposées : `nom_ecole`, `type`, `centre_services`, `region`, `latitude`, `longitude`.

Notes : Le jeu officiel contient plusieurs couches; la couche Écoles publiques est souvent la plus simple pour l'enseignement de la science des données.

Les fichiers bruts ne sont pas redistribués par défaut. Déposer la ressource officielle retenue dans `data_raw/`, puis utiliser `preparation.R` pour produire une version préparée dans `data_processed/`.
