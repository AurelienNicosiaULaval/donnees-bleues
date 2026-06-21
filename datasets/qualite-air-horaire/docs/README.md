# Qualité de l'air au Québec

Source officielle : https://www.donneesquebec.ca/recherche/dataset/rsqaq-donnees-horaires-continues

Cette fiche utilise la ressource `RSQAQ - Données continues horaires 2025` du paquet CKAN `RSQAQ - Données horaires continues`.

Le script `preparation.R` télécharge :

- les métadonnées CKAN du paquet;
- le CSV officiel 2025;
- puis produit des résumés pédagogiques dans `data/processed/qualite-air-horaire/`.

Fichiers préparés principaux :

- `resume_journalier_contaminants_2025.csv`;
- `resume_contaminants_2025.csv`;
- `resume_stations_2025.csv`;
- `episodes_pm25_2025.csv`;
- `valeurs_manquantes_contaminants_2025.csv`.

Question pédagogique principale : quelles journées présentent les moyennes journalières de PM2.5 les plus élevées, et que peut-on conclure prudemment?

Précaution : les valeurs sont descriptives. Une valeur élevée n'identifie pas automatiquement une cause environnementale.
