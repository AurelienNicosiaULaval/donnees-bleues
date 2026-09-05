# Laboratoire - Écoles Québec
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
print(donnees |> summarise(liens = n(), organismes = n_distinct(CD_ORGNS), immeubles = n_distinct(CD_IMM)))
# La carte représente des immeubles : retirer les répétitions de leur identifiant.
immeubles <- donnees |> distinct(CD_IMM, longitude, latitude) |> filter(is.finite(longitude), is.finite(latitude))
print(ggplot(immeubles, aes(x = longitude, y = latitude)) + geom_point(alpha = 0.3, size = 0.6) + coord_quickmap() +
  labs(x = "Longitude (degrés)", y = "Latitude (degrés)", subtitle = "Immeubles publiés; sans mesure de l’accès scolaire"))
