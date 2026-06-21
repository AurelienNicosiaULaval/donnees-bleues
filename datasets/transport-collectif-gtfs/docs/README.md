# Horaires, arrêts et parcours GTFS du RTC

Source officielle : https://www.donneesquebec.ca/recherche/dataset/rtc-gtfs-arrets-et-les-parcours

ZIP GTFS : https://cdn.rtcquebec.ca/Site_Internet/DonneesOuvertes/googletransit.zip

Question d'analyse : comment décrire l'offre planifiée du RTC sans la confondre avec l'achalandage ou les retards?

Tables préparées principales :

- `data/processed/transport-collectif-gtfs/arrets_gtfs_rtc.csv`
- `data/processed/transport-collectif-gtfs/parcours_gtfs_rtc.csv`
- `data/processed/transport-collectif-gtfs/trajets_gtfs_rtc.csv`
- `data/processed/transport-collectif-gtfs/resume_parcours_gtfs_rtc.csv`
- `data/processed/transport-collectif-gtfs/resume_accessibilite_gtfs_rtc.csv`

Les fichiers bruts ne sont pas redistribués. Exécuter `datasets/transport-collectif-gtfs/preparation.R` depuis la racine du projet pour télécharger le ZIP officiel et reconstruire les tables préparées.
