# Laboratoire - Condamnations alimentaires
# Ouvrir le projet RStudio de l’archive, puis exécuter ce script.
# Source : https://www.donneesquebec.ca/recherche/dataset/condamnations-des-etablissements-alimentaires-et-condamnations-concernant-le-bien-etre-des-anim
# Les données de classe sont figées; ce script ne les télécharge pas.

library(dplyr)
library(readr)
library(ggplot2)

donnees <- read_csv("data/processed/condamnations-alimentaires-quebec/condamnations_alimentaires_quebec.csv", show_col_types = FALSE)
stopifnot(nrow(donnees) > 0)

resume <- donnees |> count(Type_etablissement, sort = TRUE)
print(resume)
print(donnees |> summarise(amende_mediane_dollars = median(amende_num, na.rm = TRUE),
                          amende_maximale_dollars = max(amende_num, na.rm = TRUE)))
print(ggplot(head(resume, 10), aes(x = reorder(Type_etablissement, n), y = n)) + geom_col() + coord_flip() +
  labs(x = "Type d’établissement", y = "Condamnations dans la version pédagogique (nombre)",
       subtitle = "Les établissements inspectés ne constituent pas un échantillon aléatoire"))
