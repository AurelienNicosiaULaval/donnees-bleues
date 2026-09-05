# Mini-projet - Rapport BIXI sur un instantané GBFS
# Ouvrir le projet RStudio de l’archive, puis exécuter ce script.
# Source : https://www.donneesquebec.ca/recherche/dataset/vmtl-bixi-etat-des-stations
# Les données de classe sont figées; ce script ne les télécharge pas.

library(dplyr)
library(readr)
library(ggplot2)

donnees <- read_csv("data/processed/bixi/stations_bixi_snapshot.csv", show_col_types = FALSE)
stopifnot(nrow(donnees) > 0)

selection <- donnees |>
  filter(capacity > 0, is.finite(taux_occupation)) |>
  mutate(groupe_capacite = factor(groupe_capacite, levels = c(
    "Petite station, 15 bornes ou moins", "Station moyenne, 16 à 25 bornes",
    "Grande station, 26 à 35 bornes", "Très grande station, 36 bornes ou plus")))
stopifnot(!anyNA(selection$groupe_capacite))
resume <- selection |> group_by(groupe_capacite, etat_operationnel) |> summarise(
  stations = n(), occupation_mediane = median(taux_occupation),
  proportion_sans_velo = mean(num_bikes_available == 0), .groups = "drop")
print(resume)
print(donnees |> summarise(debut_rapport = min(last_reported_datetime, na.rm = TRUE),
                          fin_rapport = max(last_reported_datetime, na.rm = TRUE)))
print(ggplot(selection, aes(x = groupe_capacite, y = taux_occupation)) + geom_boxplot() + coord_flip() +
  scale_y_continuous(labels = scales::label_percent()) +
  labs(x = "Groupe de capacité", y = "Vélos disponibles / capacité (%)",
       subtitle = "Comparer la disponibilité; la demande et le rééquilibrage ne sont pas observés"))
