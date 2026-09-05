# Laboratoire - Catégories de requêtes 311 par arrondissement
# Ouvrir le projet RStudio de l’archive, puis exécuter ce script.
# Source : https://www.donneesquebec.ca/recherche/dataset/vmtl-requete-311
# Les données de classe sont figées; ce script ne les télécharge pas.

library(dplyr)
library(readr)
library(ggplot2)

donnees <- read_csv("data/processed/requetes-311/requetes_311_non_information_echantillon.csv", show_col_types = FALSE)
stopifnot(nrow(donnees) > 0)

resume <- donnees |> count(activite, sort = TRUE) |> slice_head(n = 10)
print(resume)
print(donnees |> count(nature))
print(ggplot(resume, aes(x = reorder(activite, n), y = n)) + geom_col() + coord_flip() +
  labs(x = "Activité", y = "Demandes dans l’échantillon (nombre)",
       subtitle = "Échantillon de demandes hors Information; pas la fréquence des problèmes"))
