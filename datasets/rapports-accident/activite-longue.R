# Mini-projet - Modéliser prudemment la gravité des accidents
# Ouvrir le projet RStudio de l’archive, puis exécuter ce script.
# Source : https://www.donneesquebec.ca/recherche/dataset/rapports-d-accident
# Les données de classe sont figées; ce script ne les télécharge pas.

library(dplyr)
library(readr)
library(ggplot2)

donnees <- read_csv("data/processed/rapports-accident/rapports_accident_2022_prepares.csv", show_col_types = FALSE)
stopifnot(nrow(donnees) > 0)

resume <- donnees |> count(region_nom, gravite) |> group_by(region_nom) |> mutate(proportion = n / sum(n)) |> ungroup()
print(resume)
print(ggplot(resume, aes(x = region_nom, y = proportion, fill = gravite)) + geom_col() + coord_flip() +
  scale_y_continuous(labels = scales::label_percent()) +
  labs(x = "Région", y = "Composition des accidents enregistrés (%)", fill = "Gravité",
       subtitle = "Comparaison des accidents déclarés; aucune mesure d’exposition routière"))
