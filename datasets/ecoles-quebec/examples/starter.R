# Exemple de départ : Établissements scolaires du Québec

library(dplyr)
library(ggplot2)
library(readr)

source_page <- "https://www.donneesquebec.ca/recherche/dataset/localisation-des-etablissements-d-enseignement-du-reseau-scolaire-au-quebec"
source_url <- "https://www.donneesquebec.ca/recherche/dataset/2d3b5cf8-b347-49c7-ad3b-bd6a9c15e443/resource/c6640a54-bc4b-43ec-864e-6c325dce61bc/download/pps_public_ecole.csv"

# 1. Consulter source_page.
# 2. Exécuter preparation.R pour télécharger source_url et créer la version préparée.
# 3. Comparer les comptes de lignes, d'organismes et d'immeubles.

donnees <- read_csv(
  "data/processed/ecoles-quebec/ecoles_publiques_quebec.csv",
  show_col_types = FALSE
)

glimpse(donnees)

donnees |>
  summarise(
    liens_ecole_immeuble = n(),
    organismes = n_distinct(CD_ORGNS),
    immeubles = n_distinct(CD_IMM),
    regions = n_distinct(region_administrative)
  )

donnees |>
  count(region_administrative, sort = TRUE)
