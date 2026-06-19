# Exemple de départ : Réseaux de transport collectif GTFS au Québec (STT-1100)

library(dplyr)
library(ggplot2)
library(readr)

source_page <- "https://www.donneesquebec.ca/recherche/dataset/rtc-gtfs-arrets-et-les-parcours"

# 1. Consulter source_page.
# 2. Télécharger la ressource officielle retenue.
# 3. La placer dans data_raw/source_officielle_a_renommer.csv.
# 4. Exécuter preparation.R pour créer une version préparée.

donnees <- read_csv("data_processed/transport_collectif.csv", show_col_types = FALSE)

glimpse(donnees)
