# Laboratoire - Visites par habitant dans les bibliothèques
# Ouvrir le projet RStudio de l’archive, puis exécuter ce script.
# Source : https://www.donneesquebec.ca/recherche/dataset/statistiques_des_bibliotheques_publiques_du_quebec
# Les données de classe sont figées; ce script ne les télécharge pas.

library(dplyr)
library(readr)
library(ggplot2)

donnees <- read_csv("data/processed/bibliotheques-quebec/statistiques_bibliotheques_quebec_2024_selection.csv", show_col_types = FALSE)
stopifnot(nrow(donnees) > 0)

selection <- donnees |> filter(!is.na(population_desservie), population_desservie > 0,
                              is.finite(visites_par_habitant))
stopifnot(nrow(selection) > 0,
  max(abs(selection$visites_par_habitant - selection$visites_total / selection$population_desservie)) < 0.01)
resume <- selection |> arrange(desc(visites_par_habitant)) |>
  select(bibliotheque, population_desservie, visites_total, visites_par_habitant) |> slice_head(n = 8)
print(resume)
print(ggplot(selection, aes(x = visites_par_habitant)) + geom_histogram(bins = 20) +
  labs(x = "Visites par personne desservie (visites/personne)", y = "Bibliothèques (nombre)"))
