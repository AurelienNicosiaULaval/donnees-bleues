# Mini-rapport sur les niveaux d'eau d'inondation
# Ouvrir le projet RStudio de l’archive, puis exécuter ce script.
# Source : https://www.donneesquebec.ca/recherche/dataset/niveaux-deau-inondation-msp
# Les données de classe sont figées; ce script ne les télécharge pas.

# Load libraries
library(dplyr)
library(ggplot2)
library(readr)

# Prepare official CSV

# Import prepared files
niveaux <- read_csv(
  "data/processed/niveaux-eau-inondation/niveaux_eau_inondation.csv",
  show_col_types = FALSE
)

valeurs_manquantes <- read_csv(
  "data/processed/niveaux-eau-inondation/valeurs_manquantes_niveaux_eau_inondation.csv",
  show_col_types = FALSE
)

resume_annee <- read_csv(
  "data/processed/niveaux-eau-inondation/resume_annee_niveaux_eau_inondation.csv",
  show_col_types = FALSE
)

resume_type <- read_csv(
  "data/processed/niveaux-eau-inondation/resume_type_niveaux_eau_inondation.csv",
  show_col_types = FALSE
)

# Basic checks
print(niveaux |>
  summarise(
    lignes = n(),
    premiere_date = min(date_obs),
    derniere_date = max(date_obs),
    altitude_min = min(alt_m_cgvd),
    altitude_max = max(alt_m_cgvd)
  ))

# Observation types
print(resume_type)

# Missing values
print(valeurs_manquantes |>
  filter(n_missing > 0) |>
  arrange(desc(n_missing)))

print(ggplot(niveaux, aes(x = long_wgs84, y = lat_wgs84, color = type_obs)) +
  geom_point(alpha = 0.65, size = 1.2) +
  coord_quickmap() +
  facet_wrap(~ annee_obs) +
  labs(
    x = "Longitude",
    y = "Latitude",
    color = "Type",
    title = "Marqueurs de niveaux d'eau par année d'observation",
    subtitle = "Les facettes ne doivent pas être interprétées comme une fréquence annuelle des inondations"
  ))
