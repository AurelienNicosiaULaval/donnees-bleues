# Laboratoire - Diffusion et indices de défavorisation
# Ouvrir le projet RStudio de l’archive, puis exécuter ce script.
# Source : https://www.donneesquebec.ca/recherche/dataset/indices-de-defavorisation/resource/6c5d4a5d-ba3b-40a6-b570-916f43ab622c
# Les données de classe sont figées; ce script ne les télécharge pas.

library(dplyr)
library(readr)
library(ggplot2)

donnees <- read_csv("data/processed/defavorisation-ecoles-primaires/defavorisation_ecoles_primaires.csv", show_col_types = FALSE)
stopifnot(nrow(donnees) > 0)

print(donnees |> count(Diffusion))
selection <- donnees |> filter(Diffusion == "OUI", is.finite(IMSE), is.finite(SFR))
stopifnot(nrow(selection) > 2)
resume <- selection |> summarise(ecoles = n(), correlation_pearson = cor(IMSE, SFR),
                                imse_median = median(IMSE), sfr_median = median(SFR))
print(resume)
print(ggplot(selection, aes(x = SFR, y = IMSE)) + geom_point(alpha = 0.4) +
  labs(x = "Seuil de faible revenu (indice SFR)", y = "Indice de milieu socioéconomique (IMSE)",
       subtitle = "Écoles dont les indices sont diffusés; aucune inférence individuelle"))
