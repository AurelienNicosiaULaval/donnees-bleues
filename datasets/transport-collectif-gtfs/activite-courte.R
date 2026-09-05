# Cartographier les arrêts du RTC
# Ouvrir le projet RStudio de l’archive, puis exécuter ce script.
# Source : https://www.donneesquebec.ca/recherche/dataset/rtc-gtfs-arrets-et-les-parcours
# Les données de classe sont figées; ce script ne les télécharge pas.

library(dplyr)
library(readr)
library(ggplot2)

donnees <- read_csv("data/processed/transport-collectif-gtfs/arrets_gtfs_rtc.csv", show_col_types = FALSE)
stopifnot(nrow(donnees) > 0)

resume <- donnees |> count(wheelchair_boarding_label, sort = TRUE)
print(resume)
print(donnees |> summarise(arrets = n(), identifiants = n_distinct(stop_id), information_absente = sum(wheelchair_boarding == 0, na.rm = TRUE)))
print(ggplot(resume, aes(x = wheelchair_boarding_label, y = n)) + geom_col() + coord_flip() +
  labs(x = "Codage GTFS", y = "Arrêts (nombre)", subtitle = "Une information absente n’est pas un arrêt déclaré inaccessible"))
