# Mini-projet - Saisonnalité des demandes 311
# Ouvrir le projet RStudio de l’archive, puis exécuter ce script.
# Source : https://www.donneesquebec.ca/recherche/dataset/vmtl-requete-311
# Les données de classe sont figées; ce script ne les télécharge pas.

library(dplyr)
library(readr)
library(ggplot2)

donnees <- read_csv("data/processed/requetes-311/requetes_311_non_information_echantillon.csv", show_col_types = FALSE)
stopifnot(nrow(donnees) > 0)

selection <- donnees |> filter(!is.na(date_creation)) |> mutate(mois = format(date_creation, "%Y-%m"))
resume <- selection |> count(mois, nature)
print(resume)
print(ggplot(resume, aes(x = mois, y = n, colour = nature, group = nature)) + geom_line() +
  labs(x = "Mois", y = "Demandes dans l’échantillon (nombre)", colour = "Nature",
       subtitle = "Période finale potentiellement incomplète; l’échantillon n’est pas un recensement") +
  theme(axis.text.x = element_text(angle = 60, hjust = 1)))
print(donnees |> group_by(arrondissement) |> summarise(demandes = n(),
  delais_connus = sum(is.finite(delai_statut_jours)), delai_median_jours = median(delai_statut_jours, na.rm = TRUE), .groups = "drop"))
# Le délai de changement de statut n'est pas nécessairement un délai de résolution.
