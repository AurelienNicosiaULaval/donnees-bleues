# Couverture territoriale et temporelle des stations RSQAQ
# Ouvrir le projet RStudio de l’archive, puis exécuter ce script.
# Source : https://www.donneesquebec.ca/recherche/dataset/rsqaq-stations
# Les données de classe sont figées; ce script ne les télécharge pas.

# Load libraries
library(dplyr)
library(ggplot2)
library(readr)

# Import prepared files
stations <- read_csv(
  "data/processed/qualite-air/rsqaq_stations.csv",
  show_col_types = FALSE
)

resume_regions <- read_csv(
  "data/processed/qualite-air/resume_regions_rsqaq_stations.csv",
  show_col_types = FALSE
)

resume_decennies <- read_csv(
  "data/processed/qualite-air/resume_decennies_ouverture_rsqaq_stations.csv",
  show_col_types = FALSE
)

valeurs_manquantes <- read_csv(
  "data/processed/qualite-air/valeurs_manquantes_rsqaq_stations.csv",
  show_col_types = FALSE
)

# Regions with the most stations without a closing date
print(resume_regions |>
  arrange(desc(n_sans_date_fermeture), desc(n_stations)) |>
  select(region_administrative, n_stations, n_sans_date_fermeture, n_fermees) |>
  head(10))

# Openings by decade
print(ggplot(resume_decennies, aes(x = decennie_ouverture, y = n_stations)) +
  geom_col(fill = "#325EA8") +
  labs(
    x = "Décennie d'ouverture",
    y = "Nombre de stations",
    title = "Ouvertures de stations RSQAQ par décennie"
  ))

# Simple point map
print(ggplot(stations, aes(x = longitude, y = latitude, color = station_sans_date_fermeture)) +
  geom_point(alpha = 0.75) +
  coord_fixed() +
  labs(
    x = "Longitude",
    y = "Latitude",
    color = "Sans date de fermeture",
    title = "Localisation des stations RSQAQ publiées",
    subtitle = "Carte de stations, pas carte de pollution"
  ))
