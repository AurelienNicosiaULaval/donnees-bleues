# Flux temps réel STM et ponctualité des bus

Source officielle : https://www.donneesquebec.ca/recherche/dataset/vmtl-stm-bus-temps-reel-gtfs-realtime

Question d'analyse : Comment construire un protocole reproductible pour mesurer la ponctualité à partir d'un flux temps réel?

Cette fiche est une fiche de protocole. Le paquet CKAN vérifié expose une ressource GTFS-realtime qui pointe vers le portail développeur STM. Il ne publie pas une table historique de retards directement téléchargeable.

Variables pédagogiques possibles : `collection_time`, `message_type`, `route_id`, `trip_id`, `vehicle_id`, `stop_id`, `delay_seconds`, `retard_minutes`, `latitude`, `longitude`, `occupancy_status`.

Notes :

- `retard_minutes` est une variable dérivée, pas une colonne brute garantie.
- Le nombre de lignes historiques est : Je ne sais pas.
- Une analyse de ponctualité exige une clé API, un protocole d'archivage et une documentation des données manquantes.
- Les clés API ne doivent jamais être publiées dans Git.

Exécuter `preparation.R` depuis la racine du projet pour valider les métadonnées CKAN et produire les fichiers de résumé pédagogiques.
