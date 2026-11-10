# Vérifier la provenance et les comptes agrégés sans exposer le fichier individuel.
verifier_parc_api <- function() {
  source('R/utils_downloads.R', local = TRUE)
  source('datasets/vehicules-canada-2025/preparation-api.R', local = TRUE)
  archive <- 'datasets/vehicules-canada-2025/snapshots/20261110T200805Z/source-api.zip'
  stopifnot(identical(digest::digest(file = archive, algo = 'sha256'), trimws(readLines(paste0(archive, '.sha256'))[1])))
  entrees <- utils::unzip(archive, list = TRUE)$Name
  stopifnot(!any(grepl('ressource[.]csv$', entrees)))
  dossier <- tempfile(); dir.create(dossier); on.exit(unlink(dossier, recursive = TRUE), add = TRUE)
  utils::unzip(archive, exdir = dossier)
  meta <- file.path(dossier, 'package.json'); recu <- jsonlite::read_json(paste0(meta, '.source.json'))
  ancien <- Sys.getenv('DB_OFFLINE', unset = NA_character_)
  on.exit(if (is.na(ancien)) Sys.unsetenv('DB_OFFLINE') else Sys.setenv(DB_OFFLINE = ancien), add = TRUE)
  Sys.setenv(DB_OFFLINE = 'true'); download_source(recu$source_url, meta)
  paquet <- jsonlite::read_json(meta); info <- jsonlite::read_json(file.path(dossier, 'provenance-api.json'))
  r <- Filter(function(x) identical(x$id, '36e97894-fd4a-46fd-ab89-9e46329d60a9'), paquet$result$resources)
  table <- file.path(dossier, 'parc-activite.csv'); x <- readr::read_csv(table, show_col_types = FALSE)
  stopifnot(isTRUE(paquet$success), length(r) == 1L, identical(r[[1]]$url, info$source_url),
    identical(info$source_sha256, '84f57d77dca8eee189c734c79cde757bf0311ebb5d26694278c31b4db7e331f9'),
    identical(digest::digest(file = table, algo = 'sha256'), '4fb91d7190b9c6c62d97c2d23168a1c318206a969bfe3d255bc0d1c42cf30dca'),
    nrow(x) == 152L, sum(x$number_registered_qc) == 5507330L, !'NOSEQ_VEH' %in% names(x))
  faux <- file.path(dossier, 'modifie.csv'); writeLines('AN,CLAS\n2022,PAU', faux)
  stopifnot(inherits(tryCatch(preparer_parc_api(faux), error = identity), 'error'))
  message('SAAQ : source, comptes, copie et refus d’une source modifiée vérifiés.')
}
verifier_parc_api()
