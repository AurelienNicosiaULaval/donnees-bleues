# PM2.5 et journées élevées en 2025
# Ouvrir le projet RStudio de l’archive, puis exécuter ce script.
# Source : https://www.donneesquebec.ca/recherche/dataset/rsqaq-donnees-horaires-continues
# Les données de classe sont figées; ce script ne les télécharge pas.

# Load libraries
library(dplyr)
library(ggplot2)
library(readr)

# Prepare and import data

air_jour <- read_csv(
  "data/processed/qualite-air-horaire/resume_journalier_contaminants_2025.csv",
  show_col_types = FALSE
)

pm25 <- air_jour |>
  filter(contaminant_source == "PM2.5-T640", n_heures_valides >= 18)

print(pm25 |>
  arrange(desc(moyenne)) |>
  select(date, station_name, n_heures_valides, moyenne, maximum) |>
  slice_head(n = 10))

print(ggplot(pm25, aes(x = date, y = moyenne, group = station_id)) +
  geom_line(alpha = 0.25, linewidth = 0.3) +
  labs(
    title = "Moyennes journalières de PM2.5 par station, 2025",
    x = "Date",
    y = "Concentration moyenne de PM2,5 (µg/m³)",
    subtitle = "Jours en HNE; au moins 18 heures valides"
  ) +
  theme_minimal())
