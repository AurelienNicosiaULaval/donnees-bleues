# Préparer les variables de classe à partir de l'échantillon de l'API.
library(dplyr)
library(readr)
preparer_requetes_api <- function(fichier) {
  x <- readr::read_csv(fichier, col_types = readr::cols(.default = readr::col_character()), show_col_types = FALSE)
  champs <- c('NATURE', 'ACTI_NOM', 'ARRONDISSEMENT', 'DDS_DATE_CREATION', 'DATE_DERNIER_STATUT')
  if (!identical(names(x), champs) || !nrow(x) || any(x$NATURE == 'Information', na.rm = TRUE))
    stop('Échantillon 311 invalide.', call. = FALSE)
  date_creation <- as.POSIXct(x$DDS_DATE_CREATION, format = '%Y-%m-%dT%H:%M:%S', tz = 'UTC')
  date_statut <- as.POSIXct(x$DATE_DERNIER_STATUT, format = '%Y-%m-%dT%H:%M:%S', tz = 'UTC')
  if (any(!is.na(x$DDS_DATE_CREATION) & is.na(date_creation)) || any(!is.na(x$DATE_DERNIER_STATUT) & is.na(date_statut)))
    stop('Une date 311 ne peut pas être interprétée.', call. = FALSE)
  tibble::tibble(nature = stringr::str_squish(x$NATURE), activite = stringr::str_squish(x$ACTI_NOM),
    arrondissement = stringr::str_squish(x$ARRONDISSEMENT), date_creation = date_creation,
    delai_statut_jours = as.numeric(difftime(date_statut, date_creation, units = 'days'))) |>
    arrange(date_creation)
}
