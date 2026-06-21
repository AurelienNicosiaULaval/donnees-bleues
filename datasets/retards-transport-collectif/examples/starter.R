# Exemple de départ : flux temps réel STM et ponctualité des bus

library(dplyr)
library(readr)

source_page <- "https://www.donneesquebec.ca/recherche/dataset/vmtl-stm-bus-temps-reel-gtfs-realtime"

# Ce script valide les métadonnées CKAN et produit des résumés pédagogiques.
# Il ne télécharge pas une table historique de retards, car cette table n'est
# pas exposée directement par le paquet CKAN vérifié.
source("datasets/retards-transport-collectif/preparation.R")

resume <- read_csv(
  "data/processed/retards-transport-collectif/resume_retards_transport.csv",
  show_col_types = FALSE
)

variables <- read_csv(
  "data/processed/retards-transport-collectif/variables_gtfs_realtime_retards_transport.csv",
  show_col_types = FALSE
)

resume |>
  select(
    access_date,
    n_resources_ckan,
    n_gtfs_resources,
    n_developer_portal_resources,
    n_direct_download_resources,
    source_requires_developer_account
  )

variables |>
  count(message_type, sort = TRUE)
