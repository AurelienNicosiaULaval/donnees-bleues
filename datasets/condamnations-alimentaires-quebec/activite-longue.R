# Mini-projet - Condamnations alimentaires
# Ouvrir le projet RStudio de l’archive, puis exécuter ce script.
# Source : https://www.donneesquebec.ca/recherche/dataset/condamnations-des-etablissements-alimentaires-et-condamnations-concernant-le-bien-etre-des-anim
# Les données de classe sont figées; ce script ne les télécharge pas.

library(dplyr)
library(readr)
library(ggplot2)

donnees <- read_csv("data/processed/condamnations-alimentaires-quebec/condamnations_alimentaires_quebec.csv", show_col_types = FALSE)
stopifnot(nrow(donnees) > 0)

resume <- donnees |> group_by(Type_etablissement) |> summarise(
  condamnations = n(), amende_mediane_dollars = median(amende_num, na.rm = TRUE),
  delai_median_jours = median(delai_infraction_jugement_jours, na.rm = TRUE), .groups = "drop")
print(resume)
print(ggplot(donnees, aes(x = delai_infraction_jugement_jours)) + geom_histogram(bins = 20) +
  labs(x = "Délai entre infraction et jugement (jours)", y = "Condamnations (nombre)",
       subtitle = "Délais administratifs; sans mesure du risque sanitaire"))
