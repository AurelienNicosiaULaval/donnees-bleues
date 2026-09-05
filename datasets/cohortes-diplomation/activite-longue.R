# Tendances de diplomation selon l'IMSE
# Ouvrir le projet RStudio de l’archive, puis exécuter ce script.
# Source : https://statistique.quebec.ca/fr/produit/publication/indicateurs-progres-ecart-diplomation
# Les données de classe sont figées; ce script ne les télécharge pas.

library(dplyr)
library(readr)
library(ggplot2)

donnees <- read_csv("data/processed/cohortes-diplomation/ecart_diplomation_imse.csv", show_col_types = FALSE)
stopifnot(nrow(donnees) > 0)

series <- donnees |> tidyr::pivot_longer(
  cols = c(taux_diplomation_decile_imse_1, taux_diplomation_decile_imse_10),
  names_to = "groupe", values_to = "taux")
print(ggplot(series, aes(x = annee_scolaire_fin_suivi, y = taux, group = groupe, colour = groupe)) +
  geom_line() + geom_point() + labs(x = "Année scolaire de fin de suivi", y = "Taux de diplomation (%)", colour = "Décile IMSE") +
  theme(axis.text.x = element_text(angle = 45, hjust = 1)))
resume <- donnees |> mutate(ecart_recalcule = taux_diplomation_decile_imse_1 - taux_diplomation_decile_imse_10)
stopifnot(max(abs(resume$ecart_recalcule - resume$ecart_points_pourcentage), na.rm = TRUE) <= 0.2)
print(ggplot(resume, aes(x = annee_scolaire_fin_suivi, y = ecart_recalcule, group = 1)) +
  geom_line() + geom_point() + labs(x = "Année scolaire de fin de suivi", y = "Écart entre déciles 1 et 10 (points de pourcentage)") +
  theme(axis.text.x = element_text(angle = 45, hjust = 1)))
