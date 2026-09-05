# Lire prudemment des données de sécurité publique
# Ouvrir le projet RStudio de l’archive, puis exécuter ce script.
# Source : https://www.donneesquebec.ca/recherche/dataset/vmtl-actes-criminels
# Les données de classe sont figées; ce script ne les télécharge pas.

library(dplyr)
library(readr)
library(ggplot2)

donnees <- read_csv("data/processed/actes-criminels-montreal/actes_criminels_montreal.csv", show_col_types = FALSE)
stopifnot(nrow(donnees) > 0)

resume <- donnees |> count(categorie, sort = TRUE)
print(resume)
print(donnees |> summarise(premiere_date = min(date), derniere_date = max(date)))
graphique <- ggplot(resume, aes(x = reorder(categorie, n), y = n)) +
  geom_col() + coord_flip() + labs(x = "Catégorie", y = "Actes enregistrés (nombre)")
print(graphique)
