# Laboratoire - Disponibilité instantanée des stations BIXI
# Ouvrir le projet RStudio de l’archive, puis exécuter ce script.
# Source : https://www.donneesquebec.ca/recherche/dataset/vmtl-bixi-etat-des-stations
# Les données de classe sont figées; ce script ne les télécharge pas.

library(dplyr)
library(readr)
library(ggplot2)

donnees <- read_csv("data/processed/bixi/stations_bixi_snapshot.csv", show_col_types = FALSE)
stopifnot(nrow(donnees) > 0)

selection <- donnees |> filter(capacity > 0, is.finite(taux_occupation))
stopifnot(nrow(selection) > 0,
  max(abs(selection$taux_occupation - selection$num_bikes_available / selection$capacity)) < 1e-8)
resume <- selection |> summarise(stations = n(),
  proportion_sous_25_pourcent = mean(taux_occupation < 0.25),
  stations_sans_velo = sum(num_bikes_available == 0))
print(resume)
print(selection |> filter(num_bikes_available == 0) |> select(station_id, name, capacity, etat_operationnel))
print(ggplot(selection, aes(x = taux_occupation)) + geom_histogram(binwidth = 0.1, boundary = 0) +
  scale_x_continuous(labels = scales::label_percent()) +
  labs(x = "Vélos disponibles / capacité (%)", y = "Stations (nombre)",
       subtitle = "Instantané de disponibilité; ne mesure pas la demande"))
