# Mini-projet - Défavorisation des écoles
# Ouvrir le projet RStudio de l’archive, puis exécuter ce script.
# Source : https://www.donneesquebec.ca/recherche/dataset/indices-de-defavorisation/resource/6c5d4a5d-ba3b-40a6-b570-916f43ab622c
# Les données de classe sont figées; ce script ne les télécharge pas.

library(dplyr)
library(readr)
library(ggplot2)

donnees <- read_csv("data/processed/defavorisation-ecoles-primaires/defavorisation_ecoles_primaires.csv", show_col_types = FALSE)
stopifnot(nrow(donnees) > 0)

selection <- donnees |> filter(Diffusion == "OUI", is.finite(IMSE), is.finite(SFR), is.finite(Nbre_Eleves))
modele <- lm(IMSE ~ SFR + log1p(Nbre_Eleves), data = selection)
print(summary(modele))
resume <- data.frame(valeur_ajustee = fitted(modele), residu = residuals(modele))
print(ggplot(resume, aes(x = valeur_ajustee, y = residu)) + geom_point(alpha = 0.4) + geom_hline(yintercept = 0) +
  labs(x = "IMSE ajusté", y = "Résidu", subtitle = "Modèle descriptif sur les mêmes écoles; aucune validation prédictive"))
# Discuter l'exclusion des écoles dont les indices ne sont pas diffusés.
print(donnees |> count(Diffusion))
