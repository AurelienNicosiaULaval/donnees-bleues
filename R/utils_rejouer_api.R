# Refaire une table d'activité à partir d'une réponse API conservée et vérifiée.
rejouer_api <- function(dataset_id, resource_id, fichier, preparer, variable) {
  source_reference <- fichier
  source('R/utils_downloads.R', local = TRUE)
  source('R/utils_ckan.R', local = TRUE)
  if (grepl('[.]zip$', fichier)) {
    empreinte <- trimws(readLines(paste0(fichier, '.sha256'), warn = FALSE)[1])
    if (!identical(digest::digest(file = fichier, algo = 'sha256'), empreinte))
      stop('Archive source altérée.', call. = FALSE)
    entrees <- utils::unzip(fichier, list = TRUE)$Name
    if (any(grepl('(^/|(^|/)\\.\\.(/|$))', entrees))) stop('Chemin invalide dans l’archive.', call. = FALSE)
    extrait <- tempfile('api-source-'); dir.create(extrait)
    on.exit(unlink(extrait, recursive = TRUE), add = TRUE)
    utils::unzip(fichier, exdir = extrait)
    fichier <- file.path(extrait, 'donnees-api.csv')
  }
  ancien_mode <- Sys.getenv('DB_OFFLINE', unset = NA_character_)
  on.exit(if (is.na(ancien_mode)) Sys.unsetenv('DB_OFFLINE') else Sys.setenv(DB_OFFLINE = ancien_mode), add = TRUE)
  Sys.setenv(DB_OFFLINE = 'true')
  ckan_datastore_download(resource_id, fichier)
  recu <- jsonlite::read_json(paste0(fichier, '.source.json'))
  table <- preparer(fichier)
  date <- gsub('[-:]', '', recu$acquired_at_utc)
  dossier <- file.path('data/raw/rejeu-api', dataset_id, date)
  dir.create(dossier, recursive = TRUE, showWarnings = FALSE)
  sortie <- file.path(dossier, 'table-activite.csv')
  candidat <- tempfile(tmpdir = dossier)
  on.exit(unlink(candidat), add = TRUE)
  readr::write_csv(table, candidat, na = 'NA')
  if (file.exists(sortie)) {
    if (!identical(digest::digest(file = candidat, algo = 'sha256'), digest::digest(file = sortie, algo = 'sha256')))
      stop('La table déjà présente ne correspond pas à cette reconstruction.', call. = FALSE)
  } else if (!file.rename(candidat, sortie)) stop('Impossible de conserver la table.', call. = FALSE)
  jsonlite::write_json(list(source = source_reference, acquisition_utc = recu$acquired_at_utc,
    sha256_source = recu$sha256, sha256_table = digest::digest(file = sortie, algo = 'sha256'),
    lignes = nrow(table), colonnes = names(table)), file.path(dossier, 'rejeu.json'),
    auto_unbox = TRUE, pretty = TRUE)
  do.call(Sys.setenv, setNames(list(sortie), variable))
  message('Table reconstruite : ', sortie, '\nElle sera utilisée dans cette session R.')
  invisible(sortie)
}
