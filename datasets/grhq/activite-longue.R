# Préparer une analyse spatiale avec la GRHQ
# Ouvrir le projet RStudio de l’archive, puis exécuter ce script.
# Source : https://www.donneesquebec.ca/recherche/dataset/grhq
# Les données de classe sont figées; ce script ne les télécharge pas.

# Load libraries
library(dplyr)
library(readr)

# Prepare official metadata and index

# Import prepared files
index_grhq <- read_csv(
  "data/processed/grhq/grhq_index_telechargement.csv",
  col_types = cols(bloc = col_character(), region_hydrographique = col_character()),
  show_col_types = FALSE
)

ressources_grhq <- read_csv(
  "data/processed/grhq/ressources_grhq.csv",
  show_col_types = FALSE
)

# Select one unit
unite_choisie <- index_grhq |>
  filter(bloc == "08")
stopifnot(nrow(unite_choisie) == 1L)

print(unite_choisie |>
  select(bloc, zone, unit_kind, fgdb_url))

# Identify official resource types
print(ressources_grhq |>
  count(format, sort = TRUE))


# Une géodatabase peut être examinée dans le prolongement facultatif de la page.
