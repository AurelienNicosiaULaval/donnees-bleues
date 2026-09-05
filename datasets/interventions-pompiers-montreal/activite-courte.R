# Portrait des interventions du SIM
# Ouvrir le projet RStudio de l’archive, puis exécuter ce script.
# Source : https://donnees.montreal.ca/fr/dataset/interventions-service-securite-incendie-montreal
# Les données de classe sont figées; ce script ne les télécharge pas.

library(dplyr)
library(readr)
library(ggplot2)

donnees <- read_csv("data/processed/interventions-pompiers-montreal/interventions_pompiers_montreal.csv", show_col_types = FALSE)
stopifnot(nrow(donnees) > 0)

resume <- donnees |> count(description_groupe, sort = TRUE)
print(resume)
print(donnees |> summarise(interventions = n(), premiere_date = min(creation_date_time, na.rm = TRUE), derniere_date = max(creation_date_time, na.rm = TRUE), dates_manquantes = sum(is.na(creation_date_time))))
print(ggplot(resume, aes(x = reorder(description_groupe, n), y = n)) + geom_col() + coord_flip() +
  labs(x = "Groupe d’intervention", y = "Interventions enregistrées (nombre)"))
