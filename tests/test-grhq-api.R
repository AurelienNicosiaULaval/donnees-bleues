# Vérifier la reproduction de l'index hydrographique et ses identifiants à zéros initiaux.
verifier_grhq_api <- function() {
  source('R/utils_ckan.R', local = TRUE)
  source('datasets/grhq/preparation-api.R', local = TRUE)
  archive <- 'datasets/grhq/snapshots/20261110T162735Z/source-api.zip'
  stopifnot(identical(digest::digest(file = archive, algo = 'sha256'),
    trimws(readLines(paste0(archive, '.sha256'))[1])))
  dossier <- tempfile(); dir.create(dossier)
  on.exit(unlink(dossier, recursive = TRUE), add = TRUE)
  utils::unzip(archive, exdir = dossier)
  fichier <- file.path(dossier, 'donnees-api.csv')
  ancien <- Sys.getenv('DB_OFFLINE', unset = NA_character_)
  on.exit(if (is.na(ancien)) Sys.unsetenv('DB_OFFLINE') else Sys.setenv(DB_OFFLINE = ancien), add = TRUE)
  Sys.setenv(DB_OFFLINE = 'true')
  ckan_datastore_download('4ef6703f-0ecb-46a0-bdb4-7074f00ff514', fichier)
  x <- preparer_grhq_api(fichier)
  stopifnot(nrow(x) == 16L, sum(x$is_split_unit) == 7L,
    sum(x$bloc == '08') == 1L, x$bloc[[1]] == '00')
  message('GRHQ : copie API datée et index vérifiés.')
}
verifier_grhq_api()
