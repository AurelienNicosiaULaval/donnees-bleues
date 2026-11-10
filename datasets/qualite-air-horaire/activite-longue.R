# Tableau de bord exploratoire de la qualité de l'air
# Ouvrir le projet RStudio de l’archive, puis exécuter ce script.
# Source : https://www.donneesquebec.ca/recherche/dataset/rsqaq-donnees-horaires-continues
# La copie de classe est figée; une copie API peut être sélectionnée avant l’activité.

# Load libraries
library(dplyr)
library(ggplot2)
library(readr)

# Prepare official data

# Import prepared files
air_jour <- read_csv(
  Sys.getenv("DB_AIR_HORAIRE_SNAPSHOT", unset = "data/processed/qualite-air-horaire/resume_journalier_contaminants_2025.csv"),
  show_col_types = FALSE
)

resume_contaminants <- read_csv(
  "data/processed/qualite-air-horaire/resume_contaminants_2025.csv",
  show_col_types = FALSE
)

episodes_pm25 <- read_csv(
  "data/processed/qualite-air-horaire/episodes_pm25_2025.csv",
  show_col_types = FALSE
)

# Reconstituer les résumés horaires et journaliers de la même copie API.
if (nzchar(Sys.getenv("DB_AIR_HORAIRE_SNAPSHOT"))) {
  resume_contaminants <- air_jour |>
    distinct(contaminant_source, contaminant, unite, n_mesures, n_stations,
      premiere_mesure, derniere_mesure, moyenne_horaire, mediane_horaire, p95_horaire, maximum_horaire) |>
    rename(moyenne = moyenne_horaire, mediane = mediane_horaire,
      p95 = p95_horaire, maximum = maximum_horaire)
  episodes_pm25 <- air_jour |>
    filter(contaminant_source == "PM2.5-T640", n_heures_valides >= 18) |>
    arrange(desc(moyenne)) |>
    slice_head(n = 25)
}

# Coverage by contaminant
print(resume_contaminants |>
  arrange(desc(n_mesures)) |>
  select(contaminant_source, unite, n_mesures, n_stations, moyenne, p95, maximum))

# PM2.5 exploratory time series
pm25 <- air_jour |>
  filter(contaminant_source == "PM2.5-T640", n_heures_valides >= 18)

print(ggplot(pm25, aes(x = date, y = moyenne, group = station_id)) +
  geom_line(alpha = 0.25, linewidth = 0.3) +
  labs(
    title = "Moyennes journalières de PM2.5 par station, 2025",
    x = "Date",
    y = "Concentration moyenne de PM2,5 (µg/m³)",
    subtitle = "Jours en HNE; au moins 18 heures valides"
  ) +
  theme_minimal())

# Highest daily PM2.5 summaries
print(episodes_pm25 |>
  select(date, station_name, n_heures_valides, moyenne, maximum, p95) |>
  slice_head(n = 10))
