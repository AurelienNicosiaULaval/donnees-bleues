# Types de milieu et statut préparé des stations
# Ouvrir le projet RStudio de l’archive, puis exécuter ce script.
# Source : https://www.donneesquebec.ca/recherche/dataset/rsqaq-stations
# Les données de classe sont figées; ce script ne les télécharge pas.

# Load libraries
library(dplyr)
library(ggplot2)
library(readr)

# Import prepared data
stations <- read_csv(
  "data/processed/qualite-air/rsqaq_stations.csv",
  show_col_types = FALSE
)

# Count stations by type and prepared status
resume_types <- stations |>
  group_by(type_milieu, station_sans_date_fermeture) |>
  summarise(
    stations = n(),
    .groups = "drop"
  )

print(resume_types)

# Visualise counts
print(ggplot(
  resume_types,
  aes(x = type_milieu, y = stations, fill = station_sans_date_fermeture)
) +
  geom_col(position = "dodge") +
  labs(
    x = "Type de milieu",
    y = "Nombre de stations",
    fill = "Sans date de fermeture",
    title = "Stations RSQAQ par type de milieu",
    subtitle = "Répertoire des stations, pas mesures de pollution"
  ))
