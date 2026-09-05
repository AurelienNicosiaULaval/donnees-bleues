# Choisir une unité GRHQ avec l'index de téléchargement
# Ouvrir le projet RStudio de l’archive, puis exécuter ce script.
# Source : https://www.donneesquebec.ca/recherche/dataset/grhq
# Les données de classe sont figées; ce script ne les télécharge pas.

# Load libraries
library(dplyr)
library(readr)

# Prepare official metadata and index

# Import prepared index
index_grhq <- read_csv(
  "data/processed/grhq/grhq_index_telechargement.csv",
  col_types = cols(bloc = col_character(), region_hydrographique = col_character()),
  show_col_types = FALSE
)

# Count download units
print(index_grhq |>
  count(unit_kind, sort = TRUE))

# Choose one unit
unite_choisie <- index_grhq |>
  filter(bloc == "08")
stopifnot(nrow(unite_choisie) == 1L)

print(unite_choisie |>
  select(bloc, zone, fgdb_url))
