# Préparer uniquement les champs distribués dans les activités.
library(dplyr)
library(lubridate)
library(readr)
preparer_pompiers_api <- function(fichier) {
  x <- readr::read_csv(fichier, col_types = readr::cols(.default = readr::col_character()),
                       show_col_types = FALSE)
  champs <- c('CREATION_DATE_TIME', 'INCIDENT_TYPE_DESC', 'DESCRIPTION_GROUPE', 'NOM_ARROND', 'NOMBRE_UNITES')
  if (!setequal(names(x), champs) || !nrow(x)) stop('Champs des interventions absents.', call. = FALSE)
  dates <- lubridate::ymd_hms(x$CREATION_DATE_TIME, quiet = TRUE, tz = 'UTC')
  unites <- suppressWarnings(as.integer(x$NOMBRE_UNITES))
  # Une date sans heure est conservée comme heure inconnue, sans inventer minuit.
  date_seule <- grepl('^[0-9]{4}-[0-9]{2}-[0-9]{2}$', x$CREATION_DATE_TIME)
  date_seule[is.na(date_seule)] <- FALSE
  date_valide <- rep(FALSE, nrow(x))
  date_valide[date_seule] <- !is.na(as.Date(x$CREATION_DATE_TIME[date_seule], format = '%Y-%m-%d'))
  date_seule <- date_seule & date_valide
  if (any(!is.na(x$CREATION_DATE_TIME) & is.na(dates) & !date_seule) ||
      any(!is.na(x$NOMBRE_UNITES) & (is.na(unites) | as.character(unites) != x$NOMBRE_UNITES)))
    stop('Date ou nombre d’unités non reconnu dans la source.', call. = FALSE)
  x |>
    transmute(creation_date_time = dates, incident_type = INCIDENT_TYPE_DESC,
              description_groupe = DESCRIPTION_GROUPE, nom_arrond = NOM_ARROND,
              nombre_unites = unites) |>
    arrange(creation_date_time, description_groupe)
}
