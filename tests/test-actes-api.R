run_actes_api_test <- function() {
  source('R/utils_ckan.R', local = TRUE)
  source('datasets/actes-criminels-montreal/preparation-api.R', local = TRUE)
  archive <- 'datasets/actes-criminels-montreal/snapshots/20261110T152208Z/source-api.zip'
  stopifnot(identical(digest::digest(file = archive, algo = 'sha256'), trimws(readLines(paste0(archive, '.sha256'))[1])))
  extrait <- tempfile(); dir.create(extrait); on.exit(unlink(extrait, recursive = TRUE), add = TRUE)
  utils::unzip(archive, exdir = extrait)
  fichier <- file.path(extrait, 'donnees-api.csv')
  old <- Sys.getenv('DB_OFFLINE', unset = NA_character_)
  on.exit(if (is.na(old)) Sys.unsetenv('DB_OFFLINE') else Sys.setenv(DB_OFFLINE = old), add = TRUE)
  Sys.setenv(DB_OFFLINE = 'true')
  ckan_datastore_download('c6f482bf-bf0f-4960-8b2f-9982c211addd', fichier)
  source <- readr::read_csv(fichier, n_max = 1L, show_col_types = FALSE)
  stopifnot(setequal(names(source), c('CATEGORIE', 'DATE', 'QUART')))
  donnees <- preparer_actes_api(fichier)
  stopifnot(nrow(donnees) == 364906L, !anyNA(donnees$date),
            identical(names(donnees), c('categorie', 'date', 'annee', 'mois', 'quart')))
  message('Actes criminels : réponse API archivée, colonnes et dates vérifiées.')
}
run_actes_api_test()
