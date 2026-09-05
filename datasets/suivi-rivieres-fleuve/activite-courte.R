# Laboratoire - Phosphore total par station
# Ouvrir le projet RStudio de l’archive, puis exécuter ce script.
# Source : https://www.donneesquebec.ca/recherche/dataset/suivi-physicochimique-des-rivieres-et-du-fleuve
# Les données de classe sont figées; ce script ne les télécharge pas.

library(dplyr)
library(ggplot2)
library(readr)


stations <- read_csv(
  "data/processed/suivi-rivieres-fleuve/stations_qualite_eau_aires.csv",
  show_col_types = FALSE
)

stations_longues <- stations |>
  filter(!is.na(ptot_med_mgl)) |>
  count(no_bqma, hydronyme, name = "n_annees") |>
  filter(n_annees >= 20) |>
  arrange(desc(n_annees))

station_choisie <- stations_longues$no_bqma[1]

print(stations |>
  filter(no_bqma == station_choisie) |>
  ggplot(aes(x = annee, y = ptot_med_mgl)) +
  geom_line() +
  geom_point() +
  labs(
    x = "Année de fin de suivi",
    y = "Phosphore total médian (mg/l)",
    title = paste("Station", station_choisie)
  ))
