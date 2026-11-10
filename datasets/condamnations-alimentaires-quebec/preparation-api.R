# Préparer les seules variables non nominatives nécessaires aux activités.
library(dplyr)
library(readr)
preparer_condamnations_api <- function(fichier) {
  x <- readr::read_csv(fichier, show_col_types = FALSE)
  champs <- c('Type_etablissement', 'Date_infraction', 'Date_jugement', 'Date_publication', 'Amende')
  if (!all(champs %in% names(x)) || !nrow(x)) stop('Champs des condamnations absents.', call. = FALSE)
  resultat <- x |>
    transmute(Type_etablissement,
      Date_infraction = as.Date(Date_infraction, format = '%m/%d/%Y'),
      Date_jugement = as.Date(Date_jugement, format = '%m/%d/%Y'),
      Date_publication = as.Date(Date_publication, format = '%m/%d/%Y'),
      amende_num = readr::parse_number(Amende, locale = readr::locale(grouping_mark = ' ')),
      delai_infraction_jugement_jours = as.integer(Date_jugement - Date_infraction),
      delai_jugement_publication_jours = as.integer(Date_publication - Date_jugement))
  if (anyNA(resultat$Date_infraction) || anyNA(resultat$Date_jugement) ||
      anyNA(resultat$Date_publication) || anyNA(resultat$amende_num) ||
      any(resultat$delai_infraction_jugement_jours < 0))
    stop('Dates ou amendes des condamnations invalides.', call. = FALSE)
  resultat
}
