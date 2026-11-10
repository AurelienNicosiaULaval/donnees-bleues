# Contrôler la copie datée, les champs et les observations sans heure.
verifier_pompiers_api <- function() {
  source('R/utils_ckan.R', local = TRUE)
  source('datasets/interventions-pompiers-montreal/preparation-api.R', local = TRUE)
  archive <- 'datasets/interventions-pompiers-montreal/snapshots/20261110T200055Z/source-api.zip'
  stopifnot(identical(digest::digest(file = archive, algo = 'sha256'), trimws(readLines(paste0(archive, '.sha256'))[1])))
  dossier <- tempfile(); dir.create(dossier); on.exit(unlink(dossier, recursive = TRUE), add = TRUE)
  utils::unzip(archive, exdir = dossier)
  fichier <- file.path(dossier, 'donnees-api.csv')
  ancien <- Sys.getenv('DB_OFFLINE', unset = NA_character_)
  on.exit(if (is.na(ancien)) Sys.unsetenv('DB_OFFLINE') else Sys.setenv(DB_OFFLINE = ancien), add = TRUE)
  Sys.setenv(DB_OFFLINE = 'true'); ckan_datastore_download('71e86320-e35c-4b4c-878a-e52124294355', fichier)
  x <- preparer_pompiers_api(fichier)
  stopifnot(nrow(x) == 229704L, sum(is.na(x$creation_date_time)) == 1L,
    identical(names(x), c('creation_date_time', 'incident_type', 'description_groupe', 'nom_arrond', 'nombre_unites')),
    as.character(min(x$creation_date_time, na.rm = TRUE)) == '2025-01-01 00:02:31',
    as.character(max(x$creation_date_time, na.rm = TRUE)) == '2026-11-08 23:50:07')
  faux <- file.path(dossier, 'alteration.csv')
  readr::write_csv(data.frame(CREATION_DATE_TIME = 'erreur', INCIDENT_TYPE_DESC = 'A', DESCRIPTION_GROUPE = 'B',
                              NOM_ARROND = 'C', NOMBRE_UNITES = '1'), faux)
  stopifnot(inherits(tryCatch(preparer_pompiers_api(faux), error = identity), 'error'))
  message('Pompiers : réponse API, champs, dates et refus de valeur invalide vérifiés.')
}
verifier_pompiers_api()
