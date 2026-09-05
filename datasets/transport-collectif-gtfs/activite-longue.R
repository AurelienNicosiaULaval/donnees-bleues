# Offre planifiée du RTC en GTFS
# Ouvrir le projet RStudio de l’archive, puis exécuter ce script.
# Source : https://www.donneesquebec.ca/recherche/dataset/rtc-gtfs-arrets-et-les-parcours
# Les données de classe sont figées; ce script ne les télécharge pas.

library(dplyr)
library(readr)
library(ggplot2)

donnees <- read_csv("data/processed/transport-collectif-gtfs/arrets_gtfs_rtc.csv", show_col_types = FALSE)
stopifnot(nrow(donnees) > 0)

resume <- donnees |> count(wheelchair_boarding_label) |> mutate(proportion = n / sum(n))
print(resume)
print(ggplot(donnees |> filter(is.finite(longitude), is.finite(latitude)),
  aes(x = longitude, y = latitude, colour = wheelchair_boarding_label)) + geom_point(alpha = 0.5, size = 1) + coord_quickmap() +
  labs(x = "Longitude (degrés)", y = "Latitude (degrés)", colour = "Information GTFS",
       subtitle = "Offre planifiée; aucun retard ni fréquentation observés"))
