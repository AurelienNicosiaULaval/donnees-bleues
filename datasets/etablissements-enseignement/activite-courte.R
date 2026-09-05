# Cartographier une ressource scolaire sans mélanger les unités
# Ouvrir le projet RStudio de l’archive, puis exécuter ce script.
# Source : https://www.donneesquebec.ca/recherche/dataset/localisation-des-etablissements-d-enseignement-du-reseau-scolaire-au-quebec
# Les données de classe sont figées; ce script ne les télécharge pas.

# Load libraries
library(dplyr)
library(ggplot2)
library(readr)

# Prepare official files

# Import prepared data
etablissements <- read_csv(
  "data/processed/etablissements-enseignement/etablissements_enseignement_quebec.csv",
  show_col_types = FALSE
)

# Understand available units
print(etablissements |>
  count(source_resource, resource_label, unit_kind, sort = TRUE))

# Choose one resource
donnees_carte <- etablissements |>
  filter(source_resource == "public_ecole")

# Map points
print(ggplot(donnees_carte, aes(x = longitude, y = latitude)) +
  geom_point(alpha = 0.35, size = 0.8) +
  coord_quickmap() +
  labs(
    x = "Longitude",
    y = "Latitude",
    title = "Écoles publiques du Québec",
    subtitle = "Chaque point représente un lien école-immeuble"
  ))
