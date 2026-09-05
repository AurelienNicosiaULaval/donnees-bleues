# Vérifier l’accès aux données de ponctualité
# Ouvrir le projet RStudio de l’archive, puis exécuter ce script.
# Source : https://www.donneesquebec.ca/recherche/dataset/vmtl-stm-bus-temps-reel-gtfs-realtime
# Les données de classe sont figées; ce script ne les télécharge pas.

library(dplyr)
library(readr)


resume <- read_csv(
  "data/processed/retards-transport-collectif/resume_retards_transport.csv",
  show_col_types = FALSE
)

print(resume |>
  select(
    n_resources_ckan,
    n_gtfs_resources,
    n_developer_portal_resources,
    n_direct_download_resources,
    source_requires_developer_account
  ))
