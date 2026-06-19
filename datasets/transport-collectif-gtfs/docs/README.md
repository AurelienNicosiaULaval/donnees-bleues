# Réseaux de transport collectif GTFS au Québec

Source officielle : https://www.donneesquebec.ca/recherche/dataset/rtc-gtfs-arrets-et-les-parcours

Question d'analyse : Quelle est la densité des arrêts de transport collectif selon le secteur?

Variables pédagogiques proposées : `route_id`, `stop_id`, `stop_name`, `latitude`, `longitude`, `trip_id`.

Notes : La fiche source principale pointe vers le GTFS du RTC; ajouter d'autres feeds vérifiés dans les exemples selon le territoire du laboratoire.

Les fichiers bruts ne sont pas redistribués par défaut. Déposer la ressource officielle retenue dans `data_raw/`, puis utiliser `preparation.R` pour produire une version préparée dans `data_processed/`.
