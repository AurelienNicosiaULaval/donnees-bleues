# Exemple de départ : Qualité de l'air au Québec

library(dplyr)
library(ggplot2)
library(readr)

# Préparer la ressource officielle 2025 du RSQAQ.
source("datasets/qualite-air-horaire/preparation.R")

# Importer le résumé journalier préparé localement.
air_jour <- read_csv(
  "data/processed/qualite-air-horaire/resume_journalier_contaminants_2025.csv",
  show_col_types = FALSE
)

pm25 <- air_jour |>
  filter(contaminant_source == "PM2.5-T640", n_heures_valides >= 18)

pm25 |>
  arrange(desc(moyenne)) |>
  select(date, station_name, n_heures_valides, moyenne, maximum) |>
  slice_head(n = 10)

ggplot(pm25, aes(x = date, y = moyenne, group = station_id)) +
  geom_line(alpha = 0.25, linewidth = 0.3) +
  labs(
    title = "Moyennes journalières de PM2.5 par station, 2025",
    x = "Date",
    y = "Moyenne journalière des valeurs publiées"
  ) +
  theme_minimal()
