# Lire prudemment des données de sécurité publique
# Ouvrir le projet RStudio de l’archive, puis exécuter ce script.
# Source : https://www.donneesquebec.ca/recherche/dataset/vmtl-actes-criminels
# La copie de référence est figée. actualiser-api.R prépare une copie API sélectionnée pour la session.

library(dplyr)
library(readr)
library(ggplot2)

fichier <- Sys.getenv("DB_ACTES_SNAPSHOT", unset = "data/processed/actes-criminels-montreal/actes_criminels_montreal.csv")
donnees <- read_csv(fichier, show_col_types = FALSE)
stopifnot(nrow(donnees) > 0)

resume <- donnees |> count(categorie, sort = TRUE)
print(resume)
print(donnees |> summarise(premiere_date = min(date), derniere_date = max(date)))
graphique <- ggplot(resume, aes(x = reorder(categorie, n), y = n)) +
  geom_col() + coord_flip() + labs(x = "Catégorie", y = "Actes enregistrés (nombre)")
print(graphique)
