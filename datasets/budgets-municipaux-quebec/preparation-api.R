# Préparer les indicateurs de 2025 utilisés par les activités municipales.
library(dplyr)
library(readr)
preparer_budgets_api <- function(fichier) {
  x <- readr::read_csv(fichier, col_types = readr::cols(.default = readr::col_character()), show_col_types = FALSE)
  indicateurs <- c('FIALX02005', 'FIALX02006', 'FIALX02007', 'FIALX02010', 'FIALX02097')
  champs <- c('cod_geo', 'nom_organisme', 'nom_ra', 'population', 'desc_cp', indicateurs)
  if (!all(champs %in% names(x)) || !nrow(x)) stop('Champs du profil financier absents.', call. = FALSE)
  resultat <- x |>
    transmute(code_geographique = cod_geo, municipalite = nom_organisme,
      region_administrative = nom_ra, population = as.numeric(population),
      classe_population = desc_cp, across(all_of(indicateurs), as.numeric)) |>
    arrange(code_geographique)
  if (anyNA(resultat$code_geographique) || anyDuplicated(resultat$code_geographique))
    stop('Codes géographiques absents ou répétés.', call. = FALSE)
  resultat
}
