# Préparer les seules variables distribuées dans les activités.
library(dplyr)
library(readr)
preparer_actes_api <- function(fichier) {
  donnees <- read_csv(fichier, show_col_types = FALSE)
  if (!all(c('CATEGORIE', 'DATE', 'QUART') %in% names(donnees)) || !nrow(donnees))
    stop('Champs ou observations absents.', call. = FALSE)
  donnees |>
    transmute(categorie = CATEGORIE, date = as.Date(DATE),
      annee = as.integer(format(date, '%Y')), mois = format(date, '%Y-%m'), quart = QUART)
}
