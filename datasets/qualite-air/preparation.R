# Préparer les stations du Réseau de surveillance de la qualité de l'air du Québec.

library(dplyr)
library(lubridate)
library(readr)
library(stringr)

dir.create("data/raw/qualite-air", recursive = TRUE, showWarnings = FALSE)
dir.create("data/processed/qualite-air", recursive = TRUE, showWarnings = FALSE)

data_url <- "https://www.donneesquebec.ca/recherche/dataset/8656ad05-c174-41c5-9ed7-8c69d308beb9/resource/cebea532-a9e0-4a39-8c2d-54f33d937c73/download/rsqaq_station_1975-2025.csv"
raw_path <- "data/raw/qualite-air/rsqaq_station_1975-2025.csv"

download.file(data_url, raw_path, mode = "wb", quiet = TRUE)

stations <- read_csv(
  raw_path,
  locale = locale(encoding = "UTF-8"),
  show_col_types = FALSE
) |>
  rename_with(~ str_to_lower(.x)) |>
  mutate(
    date_ouverture = ymd(date_ouverture),
    date_fermeture = ymd(date_fermeture),
    station_active = is.na(date_fermeture) | date_fermeture >= Sys.Date()
  )

write_csv(stations, "data/processed/qualite-air/rsqaq_stations.csv")

message("Fichier préparé : data/processed/qualite-air/rsqaq_stations.csv")

