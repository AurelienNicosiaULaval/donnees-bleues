# Exemple de départ : Emploi régional au Québec

library(dplyr)
library(ggplot2)
library(readr)

source_page <- "https://statistique.quebec.ca/fr/document/population-active-emploi-et-chomage-regions-administratives-rmr-et-quebec"

# 1. Consulter source_page.
# 2. Télécharger la ressource officielle retenue.
# 3. La placer dans data_raw/source_officielle_a_renommer.csv.
# 4. Exécuter preparation.R pour créer une version préparée.

donnees <- read_csv("data_processed/emploi_regional.csv", show_col_types = FALSE)

glimpse(donnees)
