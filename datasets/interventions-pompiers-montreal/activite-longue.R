# Temporalité et territoire des interventions du SIM
# Ouvrir le projet RStudio de l’archive, puis exécuter ce script.
# Source : https://donnees.montreal.ca/fr/dataset/interventions-service-securite-incendie-montreal
# Les données de classe sont figées; ce script ne les télécharge pas.

library(dplyr)
library(readr)
library(ggplot2)

donnees <- read_csv("data/processed/interventions-pompiers-montreal/interventions_pompiers_montreal.csv", show_col_types = FALSE)
stopifnot(nrow(donnees) > 0)

selection <- donnees |> filter(!is.na(creation_date_time)) |> mutate(mois = format(creation_date_time, "%Y-%m"))
resume <- selection |> count(mois, description_groupe)
print(resume)
print(ggplot(resume, aes(x = mois, y = n, group = description_groupe, colour = description_groupe)) +
  geom_line() + labs(x = "Mois", y = "Interventions enregistrées (nombre)", colour = "Groupe") +
  theme(axis.text.x = element_text(angle = 45, hjust = 1)))
print(donnees |> count(nom_arrond, description_groupe))
