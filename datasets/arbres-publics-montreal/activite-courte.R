# Essences d'arbres par arrondissement
# Ouvrir le projet RStudio de l’archive, puis exécuter ce script.
# Source : https://www.donneesquebec.ca/recherche/dataset/vmtl-arbres
# Les données de classe sont figées; ce script ne les télécharge pas.

library(dplyr)
library(readr)
library(ggplot2)

donnees <- read_csv("data/processed/arbres-publics-montreal/arbres_publics_montreal.csv", col_types = cols(.default = col_skip(), arrondissement = col_character(), essence_fr = col_character(), dhp = col_double()), show_col_types = FALSE)
stopifnot(nrow(donnees) > 0)

arrondissements <- donnees |> count(arrondissement, sort = TRUE) |> filter(n >= 10000)
stopifnot(nrow(arrondissements) > 0)
arrondissement_choisi <- arrondissements$arrondissement[[1]]
resume <- donnees |> filter(arrondissement == arrondissement_choisi) |>
  count(essence_fr, sort = TRUE) |> slice_head(n = 10)
print(resume)
print(ggplot(resume, aes(x = reorder(essence_fr, n), y = n)) + geom_col() + coord_flip() +
  labs(x = "Essence", y = "Arbres inventoriés (nombre)", title = arrondissement_choisi))
