# Laboratoire - Gravité des accidents par mois
# Ouvrir le projet RStudio de l’archive, puis exécuter ce script.
# Source : https://www.donneesquebec.ca/recherche/dataset/rapports-d-accident
# Les données de classe sont figées; ce script ne les télécharge pas.

library(dplyr)
library(readr)
library(ggplot2)

donnees <- read_csv("data/processed/rapports-accident/rapports_accident_2022_prepares.csv", show_col_types = FALSE)
stopifnot(nrow(donnees) > 0)

resume <- donnees |> count(gravite, sort = TRUE) |> mutate(proportion = n / sum(n))
print(resume)
print(ggplot(resume, aes(x = reorder(gravite, n), y = n)) + geom_col() + coord_flip() +
  labs(x = "Gravité déclarée", y = "Accidents en 2022 (nombre)", subtitle = "Sans dénominateur de trafic, ces nombres ne sont pas des risques"))
