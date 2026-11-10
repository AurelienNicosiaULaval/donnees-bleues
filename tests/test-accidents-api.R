# Vérifier la projection datée et la reconstruction des activités.
verifier_accidents_api <- function() {
  source('R/utils_downloads.R', local = TRUE)
  source('datasets/rapports-accident/preparation-api.R', local = TRUE)
  archive <- 'datasets/rapports-accident/snapshots/20261110T192219Z/source-api.zip'
  stopifnot(identical(digest::digest(file = archive, algo = 'sha256'),
                      trimws(readLines(paste0(archive, '.sha256'))[1])))
  entrees <- utils::unzip(archive, list = TRUE)$Name
  stopifnot(!any(grepl('ressource[.]csv$', entrees)))
  dossier <- tempfile(); dir.create(dossier)
  on.exit(unlink(dossier, recursive = TRUE), add = TRUE)
  utils::unzip(archive, exdir = dossier)
  metadata <- file.path(dossier, 'package.json')
  recu <- jsonlite::read_json(paste0(metadata, '.source.json'))
  ancien <- Sys.getenv('DB_OFFLINE', unset = NA_character_)
  on.exit(if (is.na(ancien)) Sys.unsetenv('DB_OFFLINE') else Sys.setenv(DB_OFFLINE = ancien), add = TRUE)
  Sys.setenv(DB_OFFLINE = 'true')
  download_source(recu$source_url, metadata)
  paquet <- jsonlite::read_json(metadata)
  ressource <- Filter(function(x) identical(x$id, 'be702e5c-a25e-421e-b00d-0360c73525f1'), paquet$result$resources)
  provenance <- jsonlite::read_json(file.path(dossier, 'provenance-api.json'))
  projection <- file.path(dossier, 'projection-api.csv')
  stopifnot(isTRUE(paquet$success), length(ressource) == 1L,
            identical(ressource[[1]]$url, provenance$source_url),
            identical(provenance$source_sha256, '17fc60a26fb8ed8cc0fac871a7e4efc30cda95b93500e7a7f8213ba45008232a'),
            identical(digest::digest(file = projection, algo = 'sha256'), provenance$projection_sha256))
  x <- readr::read_csv(projection, show_col_types = FALSE)
  stopifnot(identical(names(x), c('AN', 'GRAVITE', 'REG_ADM', 'JR_SEMN_ACCDN')),
            nrow(x) == 108186L)
  table <- preparer_accidents_api(projection)
  resultat <- file.path(dossier, 'table.csv'); readr::write_csv(table, resultat)
  stopifnot(identical(digest::digest(file = resultat, algo = 'sha256'),
                      '45ddaeff5620e780edb5909a5d2a1efb0e14ab4a3b905d880532205d2ad8cd89'))
  faux <- file.path(dossier, 'modifie.csv'); writeLines('AN,GRAVITE\n2022,Léger', faux)
  stopifnot(inherits(tryCatch(extraire_accidents_api(faux), error = identity), 'error'),
            inherits(tryCatch(preparer_accidents_api(faux), error = identity), 'error'))
  message('Accidents : provenance, projection, reconstruction et refus des sources modifiées vérifiés.')
}
verifier_accidents_api()
