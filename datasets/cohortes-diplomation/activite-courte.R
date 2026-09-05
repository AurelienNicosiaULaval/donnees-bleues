# Comparer des taux de diplomation selon l'IMSE
# Ouvrir le projet RStudio de l’archive, puis exécuter ce script.
# Source : https://statistique.quebec.ca/fr/produit/publication/indicateurs-progres-ecart-diplomation
# Les données de classe sont figées; ce script ne les télécharge pas.

library(dplyr)
library(readr)
library(ggplot2)

donnees <- read_csv("data/processed/cohortes-diplomation/ecart_diplomation_imse.csv", show_col_types = FALSE)
stopifnot(nrow(donnees) > 0)

# Les deux taux sont exprimés en pourcentage : leur différence donne des points.
donnees <- donnees |> mutate(ecart_recalcule = taux_diplomation_decile_imse_1 - taux_diplomation_decile_imse_10)
stopifnot(max(abs(donnees$ecart_recalcule - donnees$ecart_points_pourcentage), na.rm = TRUE) <= 0.2)
resume <- donnees |> slice_tail(n = 3)
print(resume)
