# Mini-projet - Écoles Québec
# Ouvrir le projet RStudio de l’archive, puis exécuter ce script.
# Source : https://www.donneesquebec.ca/recherche/dataset/localisation-des-etablissements-d-enseignement-du-reseau-scolaire-au-quebec
# Les données de classe sont figées; ce script ne les télécharge pas.

library(dplyr)
library(readr)
library(ggplot2)

donnees <- read_csv("data/processed/ecoles-quebec/ecoles_publiques_quebec.csv", show_col_types = FALSE)
stopifnot(nrow(donnees) > 0)

resume <- donnees |> group_by(region_administrative) |> summarise(
  liens = n(), organismes = n_distinct(CD_ORGNS), immeubles = n_distinct(CD_IMM), .groups = "drop")
print(resume)
print(ggplot(resume, aes(x = reorder(region_administrative, immeubles), y = immeubles)) + geom_col() + coord_flip() +
  labs(x = "Région administrative", y = "Immeubles distincts (nombre)",
       subtitle = "Un nombre d’immeubles ne mesure ni les places ni les distances d’accès"))
print(donnees |> count(CD_ORGNS, name = "liens") |> count(liens, name = "organismes"))
