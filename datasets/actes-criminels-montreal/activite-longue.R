# Rapport descriptif et éthique sur les actes criminels
# Ouvrir le projet RStudio de l’archive, puis exécuter ce script.
# Source : https://www.donneesquebec.ca/recherche/dataset/vmtl-actes-criminels
# Les données de classe sont figées; ce script ne les télécharge pas.

library(dplyr)
library(readr)
library(ggplot2)

donnees <- read_csv("data/processed/actes-criminels-montreal/actes_criminels_montreal.csv", show_col_types = FALSE)
stopifnot(nrow(donnees) > 0)

# La dernière année peut être incomplète. La série annuelle est descriptive.
resume <- donnees |> count(annee, categorie)
print(resume)
graphique <- ggplot(resume, aes(x = annee, y = n, colour = categorie)) +
  geom_line() + geom_point() + labs(x = "Année", y = "Actes enregistrés (nombre)", colour = "Catégorie",
    subtitle = "Dernière année potentiellement incomplète; sans dénominateur d’exposition")
print(graphique)
print(donnees |> count(quart, categorie))
