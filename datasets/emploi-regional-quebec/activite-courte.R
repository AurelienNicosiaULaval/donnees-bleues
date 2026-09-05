# Laboratoire - Emploi régional
# Ouvrir le projet RStudio de l’archive, puis exécuter ce script.
# Source : https://statistique.quebec.ca/fr/document/population-active-emploi-et-chomage-regions-administratives-rmr-et-quebec
# Les données de classe sont figées; ce script ne les télécharge pas.

library(dplyr)
library(readr)
library(ggplot2)

donnees <- read_csv("data/processed/emploi-regional-quebec/emploi_regional_quebec.csv", show_col_types = FALSE)
stopifnot(nrow(donnees) > 0)

selection <- donnees |> filter(indicateur == "Taux de chômage", territoire %in% c("Québec", "Montréal", "Capitale-Nationale"))
stopifnot(nrow(selection) > 0, all(selection$unite == "%"))
resume <- selection |> count(territoire, indicateur_qualite)
print(resume)
print(ggplot(selection, aes(x = date, y = valeur, colour = territoire)) + geom_line() +
  labs(x = "Mois", y = "Taux de chômage (%)", colour = "Territoire",
       subtitle = "Estimations d’enquête; consulter les indicateurs de qualité"))
