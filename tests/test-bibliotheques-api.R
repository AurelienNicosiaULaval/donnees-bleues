run_bibliotheques_api_test <- function() {
  source('R/utils_ckan.R', local = TRUE)
  source('datasets/bibliotheques-quebec/preparation-api.R', local = TRUE)
  archive <- 'datasets/bibliotheques-quebec/snapshots/20261110T133457Z/source-api.zip'
  stopifnot(identical(digest::digest(file = archive, algo = 'sha256'), trimws(readLines(paste0(archive, '.sha256'))[1])))
  extrait <- tempfile(); dir.create(extrait); on.exit(unlink(extrait, recursive = TRUE), add = TRUE)
  utils::unzip(archive, exdir = extrait)
  fichier <- file.path(extrait, 'donnees-api.csv')
  old <- Sys.getenv('DB_OFFLINE', unset = NA_character_)
  on.exit(if (is.na(old)) Sys.unsetenv('DB_OFFLINE') else Sys.setenv(DB_OFFLINE = old), add = TRUE)
  Sys.setenv(DB_OFFLINE = 'true')
  ckan_datastore_download('01183d3e-c79c-4d09-915c-f35ffe4dfda8', fichier)
  donnees <- preparer_bibliotheques_api(fichier)
  stopifnot(nrow(donnees) == 188L,
    sum(donnees$visites_total, na.rm = TRUE) == 59981972,
    sum(donnees$prets_total, na.rm = TRUE) == 52513445)
  chemin <- tempfile(fileext = '.csv')
  on.exit(unlink(chemin), add = TRUE)
  readr::write_csv(donnees, chemin, na = 'NA')
  stopifnot(identical(digest::digest(file = chemin, algo = 'sha256'),
    '837a01bf5bdad05a1f877bc59f97d9f481bc99562d50cb0cb1fef61e4c9ce64f'))
  message('Bibliothèques : réponse API archivée vérifiée et table de classe reconstruite.')
}
run_bibliotheques_api_test()
