# Préparer un protocole d’archivage GTFS Realtime
# Ouvrir le projet RStudio de l’archive, puis exécuter ce script.
# Source : https://www.donneesquebec.ca/recherche/dataset/vmtl-stm-bus-temps-reel-gtfs-realtime
# Les données de classe sont figées; ce script ne les télécharge pas.

library(dplyr)
library(readr)


variables <- read_csv(
  "data/processed/retards-transport-collectif/variables_gtfs_realtime_retards_transport.csv",
  show_col_types = FALSE
)

protocole <- read_csv(
  "data/processed/retards-transport-collectif/protocole_archivage_retards_transport.csv",
  show_col_types = FALSE
)

print(variables |>
  count(message_type, sort = TRUE))

print(protocole |>
  select(step, action, point_de_controle))
