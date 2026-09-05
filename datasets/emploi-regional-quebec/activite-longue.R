# Mini-projet - Emploi régional
# Ouvrir le projet RStudio de l’archive, puis exécuter ce script.
# Source : https://statistique.quebec.ca/fr/document/population-active-emploi-et-chomage-regions-administratives-rmr-et-quebec
# Les données de classe sont figées; ce script ne les télécharge pas.

library(dplyr)
library(readr)
library(ggplot2)

donnees <- read_csv("data/processed/emploi-regional-quebec/emploi_regional_quebec.csv", show_col_types = FALSE)
stopifnot(nrow(donnees) > 0)

selection <- donnees |> filter(indicateur %in% c("Taux de chômage", "Taux d'emploi"),
  territoire %in% c("Québec", "Montréal", "Capitale-Nationale"))
resume <- selection |> group_by(indicateur, territoire) |> summarise(
  periodes = n(), valeurs_disponibles = sum(!is.na(valeur)),
  valeurs_signalees = sum(indicateur_qualite %in% c("F", "*")), .groups = "drop")
print(resume)
print(ggplot(selection, aes(x = date, y = valeur, colour = territoire, linetype = territoire)) + geom_line() +
  scale_colour_viridis_d(end = 0.75) +
  facet_wrap(vars(indicateur), scales = "free_y") +
  labs(x = "Mois", y = "Taux publié (%)", colour = "Territoire", linetype = "Territoire",
       subtitle = "Comparaison descriptive; aucune conclusion causale"))
