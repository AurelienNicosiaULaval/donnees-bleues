# Vérifier la provenance PET5, le dictionnaire de référence et la copie pédagogique.
verifier_arbres_forestiers_api <- function() {
  source('R/utils_downloads.R', local = TRUE)
  source('datasets/arbres-quebec/preparation-api.R', local = TRUE)
  archive <- 'datasets/arbres-quebec/snapshots/20261110T200718Z/source-api.zip'
  stopifnot(identical(digest::digest(file = archive, algo = 'sha256'), trimws(readLines(paste0(archive, '.sha256'))[1])))
  entrees <- utils::unzip(archive, list = TRUE)$Name
  stopifnot(!any(grepl('[.]gpkg$', entrees, ignore.case = TRUE)))
  dossier <- tempfile(); dir.create(dossier); on.exit(unlink(dossier, recursive = TRUE), add = TRUE)
  utils::unzip(archive, exdir = dossier)
  meta <- file.path(dossier, 'package.json'); recu <- jsonlite::read_json(paste0(meta, '.source.json'))
  ancien <- Sys.getenv('DB_OFFLINE', unset = NA_character_)
  on.exit(if (is.na(ancien)) Sys.unsetenv('DB_OFFLINE') else Sys.setenv(DB_OFFLINE = ancien), add = TRUE)
  Sys.setenv(DB_OFFLINE = 'true'); download_source(recu$source_url, meta)
  paquet <- jsonlite::read_json(meta); info <- jsonlite::read_json(file.path(dossier, 'provenance-api.json'))
  r <- Filter(function(x) identical(x$id, 'd09ae743-f3ca-4bfc-90d5-65c2614a679e'), paquet$result$resources)
  table <- file.path(dossier, 'arbres-activite.csv'); x <- readr::read_csv(table, show_col_types = FALSE)
  dictionnaire <- 'datasets/arbres-quebec/pipeline-reference/data_raw/PET5/DICTIONNAIRE_PLACETTE.xlsx'
  stopifnot(isTRUE(paquet$success), length(r) == 1L, identical(r[[1]]$url, info$source_url),
    identical(info$source_sha256, '45e66eeb95ea7f3e47aa0840a8a263c1cc2862ccf0b33fd5e007e353ca48174d'),
    identical(digest::digest(file = dictionnaire, algo = 'sha256'), info$dictionnaire_original_sha256),
    identical(digest::digest(file = table, algo = 'sha256'), '1af11ff0fc824f35286987928f0423441540ece1badb674f347ab05db07d4ccf'),
    nrow(x) == 200L, ncol(x) == 21L, all(table(x$species_code) == 50L))
  faux <- file.path(dossier, 'modifie.zip'); writeLines('autre source', faux)
  stopifnot(inherits(tryCatch(preparer_arbres_forestiers_api(faux, dossier), error = identity), 'error'))
  message('Arbres : source PET5, dictionnaire, copie et refus d’une source modifiée vérifiés.')
}
verifier_arbres_forestiers_api()
