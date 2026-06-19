# Exemple de départ : Retards et ponctualité du transport collectif (STT-1100)

library(dplyr)
library(ggplot2)
library(readr)

source_page <- "https://www.donneesquebec.ca/recherche/dataset/vmtl-stm-bus-temps-reel-gtfs-realtime"

# 1. Consulter source_page.
# 2. Télécharger la ressource officielle retenue.
# 3. La placer dans data_raw/source_officielle_a_renommer.csv.
# 4. Exécuter preparation.R pour créer une version préparée.

donnees <- read_csv("data_processed/retards_transport.csv", show_col_types = FALSE)

glimpse(donnees)
