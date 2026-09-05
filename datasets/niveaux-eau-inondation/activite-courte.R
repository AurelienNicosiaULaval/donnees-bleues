# Cartographier des marqueurs de niveaux d'eau
# Ouvrir le projet RStudio de l’archive, puis exécuter ce script.
# Source : https://www.donneesquebec.ca/recherche/dataset/niveaux-deau-inondation-msp
# Les données de classe sont figées; ce script ne les télécharge pas.

# Load libraries
library(dplyr)
library(ggplot2)
library(readr)

# Prepare official CSV

# Import prepared data
niveaux <- read_csv(
  "data/processed/niveaux-eau-inondation/niveaux_eau_inondation.csv",
  show_col_types = FALSE
)

# Understand observation types
print(niveaux |>
  count(type_obs, type_observation, sort = TRUE))

# Check coordinates
print(niveaux |>
  summarise(
    lignes = n(),
    coordonnees_completes = sum(has_coordinates)
  ))

# Map observations
print(ggplot(niveaux, aes(x = long_wgs84, y = lat_wgs84, color = type_obs)) +
  geom_point(alpha = 0.65, size = 1.2) +
  coord_quickmap() +
  labs(
    x = "Longitude",
    y = "Latitude",
    color = "Type",
    title = "Marqueurs de niveaux d'eau lors d'inondations",
    subtitle = "Un point représente un marqueur, pas une zone inondée"
  ))
