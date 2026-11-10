# Mini-projet - Portrait régional des bibliothèques publiques
# Ouvrir le projet RStudio de l’archive, puis exécuter ce script.
# Source : https://www.donneesquebec.ca/recherche/dataset/statistiques_des_bibliotheques_publiques_du_quebec
# Par défaut : instantané du 10 novembre 2026 obtenu avec l’API Données Québec.
# actualiser-api.R prépare un nouvel instantané et le sélectionne pour cette session.

library(dplyr)
library(readr)
library(ggplot2)

fichier <- Sys.getenv("DB_BIBLIOTHEQUES_SNAPSHOT", unset = "data/processed/bibliotheques-quebec/statistiques_bibliotheques_quebec_2024_selection.csv")
donnees <- read_csv(fichier, show_col_types = FALSE)
stopifnot(nrow(donnees) > 0)

# Un ratio par personne n'efface pas les différences de mission et de territoire.
selection <- donnees |> filter(population_desservie > 0)
resume <- selection |> group_by(categorie_bibliotheque) |> summarise(
  bibliotheques = n(), ratios_disponibles = sum(is.finite(visites_par_habitant)),
  visites_par_personne_medianes = median(visites_par_habitant, na.rm = TRUE), .groups = "drop")
print(resume)
print(selection |> summarise(bibliotheques = n(), visites_absentes = sum(!is.finite(visites_total))))
print(ggplot(selection |> filter(is.finite(visites_total)), aes(x = population_desservie, y = visites_total)) + geom_point() +
  labs(x = "Population desservie (personnes)", y = "Visites (nombre)",
       subtitle = "Données 2024; missions et territoires de desserte différents"))
