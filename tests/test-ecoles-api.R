run_ecoles_api_test <- function() {
  source('R/utils_ckan.R', local = TRUE)
  source('datasets/ecoles-quebec/preparation-api.R', local = TRUE)
  archive <- 'datasets/ecoles-quebec/snapshots/20261110T151326Z/source-api.zip'
  stopifnot(identical(digest::digest(file = archive, algo = 'sha256'), trimws(readLines(paste0(archive, '.sha256'))[1])))
  extrait <- tempfile(); dir.create(extrait); on.exit(unlink(extrait, recursive = TRUE), add = TRUE)
  utils::unzip(archive, exdir = extrait)
  fichier <- file.path(extrait, 'donnees-api.csv')
  old <- Sys.getenv('DB_OFFLINE', unset = NA_character_)
  on.exit(if (is.na(old)) Sys.unsetenv('DB_OFFLINE') else Sys.setenv(DB_OFFLINE = old), add = TRUE)
  Sys.setenv(DB_OFFLINE = 'true')
  ckan_datastore_download('c6640a54-bc4b-43ec-864e-6c325dce61bc', fichier)
  donnees <- preparer_ecoles_api(fichier)
  stopifnot(nrow(donnees) == 5457L,
    dplyr::n_distinct(donnees$CD_ORGNS) == 2797L,
    dplyr::n_distinct(donnees$CD_IMM) == 3617L,
    dplyr::n_distinct(donnees$region_administrative) == 17L)
  message('Écoles : réponse API archivée et unités de l’activité vérifiées.')
}
run_ecoles_api_test()
