# Temporalité et territoire des interventions du SIM
# Ouvrir le projet RStudio de l’archive, puis exécuter ce script.
# Source : https://donnees.montreal.ca/fr/dataset/interventions-service-securite-incendie-montreal
# Les données de classe sont figées; ce script ne les télécharge pas.

library(dplyr)
library(readr)
library(ggplot2)

donnees <- read_csv(Sys.getenv("DB_POMPIERS_SNAPSHOT", unset = "data/processed/interventions-pompiers-montreal/interventions_pompiers_montreal.csv"), show_col_types = FALSE)
stopifnot(nrow(donnees) > 0)

selection <- donnees |> filter(!is.na(creation_date_time)) |> mutate(mois = format(creation_date_time, "%Y-%m"))
stopifnot(nrow(selection) > 0)
resume <- selection |> count(mois, description_groupe)
derniere_date <- as.Date(max(selection$creation_date_time))
print(resume)
graphique <- ggplot(resume, aes(x = mois, y = n, group = description_groupe, colour = description_groupe)) +
  geom_line() + labs(x = "Mois", y = "Interventions enregistrées (nombre)", colour = "Groupe",
    caption = paste("Dernier mois possiblement incomplet. Dernière date observée :", format(derniere_date, "%Y-%m-%d"))) +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))
print(graphique)
print(donnees |> count(nom_arrond, description_groupe))
