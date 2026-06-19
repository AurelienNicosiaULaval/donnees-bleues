# Exemple de départ : Qualité de l'air au Québec (STT-1100)

library(dplyr)
library(ggplot2)
library(readr)

source_page <- "https://www.donneesquebec.ca/recherche/dataset/rsqaq-donnees-horaires-continues"

# 1. Consulter source_page.
# 2. Télécharger la ressource officielle retenue.
# 3. La placer dans data_raw/source_officielle_a_renommer.csv.
# 4. Exécuter preparation.R pour créer une version préparée.

donnees <- read_csv("data_processed/air_qualite.csv", show_col_types = FALSE)

glimpse(donnees)
