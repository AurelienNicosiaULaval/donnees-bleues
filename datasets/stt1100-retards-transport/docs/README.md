# Retards et ponctualité du transport collectif (STT-1100)

Source officielle : https://www.donneesquebec.ca/recherche/dataset/vmtl-stm-bus-temps-reel-gtfs-realtime

Question STT-1100 : Quelles lignes présentent les retards les plus importants?

Variables pédagogiques proposées : `date`, `ligne`, `retard_minutes`, `direction`, `secteur`.

Notes : Ne pas présenter retard_minutes comme une colonne brute garantie. C'est une variable dérivée possible selon le flux et le protocole de collecte.

Les fichiers bruts ne sont pas redistribués par défaut. Déposer la ressource officielle retenue dans `data_raw/`, puis utiliser `preparation.R` pour produire une version préparée dans `data_processed/`.
