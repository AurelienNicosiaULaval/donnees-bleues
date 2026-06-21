# Exemple de départ : Emploi régional au Québec

library(dplyr)
library(ggplot2)
library(readr)

source_page <- "https://statistique.quebec.ca/fr/document/population-active-emploi-et-chomage-regions-administratives-rmr-et-quebec"
source_table <- "https://statistique.quebec.ca/fr/produit/tableau/caracteristiques-du-marche-du-travail-donnees-mensuelles-desaisonnalisees-regions-administratives-et-ensemble-du-quebec"

# 1. Consulter source_page.
# 2. Consulter source_table pour comprendre le tableau 916.
# 3. Exécuter preparation.R pour télécharger le XLSX officiel et créer la version préparée.

donnees <- read_csv(
  "data/processed/emploi-regional-quebec/emploi_regional_quebec.csv",
  show_col_types = FALSE
)

glimpse(donnees)

donnees |>
  summarise(
    lignes = n(),
    indicateurs = n_distinct(indicateur),
    territoires = n_distinct(territoire),
    premiere_date = min(date),
    derniere_date = max(date),
    valeurs_f = sum(indicateur_qualite == "F", na.rm = TRUE),
    valeurs_etoile = sum(indicateur_qualite == "*", na.rm = TRUE)
  )

donnees |>
  filter(
    indicateur == "Taux de chômage",
    territoire %in% c("Québec", "Montréal", "Capitale-Nationale")
  ) |>
  ggplot(aes(x = date, y = valeur, color = territoire)) +
  geom_line(linewidth = 0.7) +
  labs(
    x = "Mois",
    y = "Taux de chômage (%)",
    color = "Territoire",
    title = "Taux de chômage mensuel, territoires sélectionnés"
  )
