# Mini-projet - Bassins versants et qualité de l'eau
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

stations_selection <- stations |>
  filter(!is.na(bv_n1m), bv_n1m == "Richelieu, Rivière")

print(stations_selection |>
  count(no_bqma, hydronyme, sort = TRUE))

print(stations_selection |>
  filter(!is.na(ptot_med_mgl)) |>
  ggplot(aes(x = annee, y = ptot_med_mgl, group = no_bqma)) +
  geom_line(alpha = 0.35) +
  labs(
    x = "Année de fin de suivi",
    y = "Phosphore total médian (mg/l)",
    title = "Stations du bassin Richelieu"
  ))

print(stations_selection |>
  distinct(no_bqma, hydronyme, latitude, longitude, pc_agricole) |>
  filter(!is.na(latitude), !is.na(longitude)))
