# Préparer les trois variables utilisées dans les activités sur les arbres.
library(dplyr)
library(readr)
preparer_arbres_api <- function(fichier) {
  x <- readr::read_csv(fichier, show_col_types = FALSE)
  if (!all(c('ARROND_NOM', 'Essence_fr', 'DHP') %in% names(x)) || !nrow(x))
    stop('Champs de l’inventaire des arbres absents.', call. = FALSE)
  x |> transmute(arrondissement = ARROND_NOM, essence_fr = Essence_fr, dhp = as.numeric(DHP))
}
