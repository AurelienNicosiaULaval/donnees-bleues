# Vérifier les copies API livrées et quelques résultats indépendants.
verifier_api <- function(id, date, resource_id, preparer, verifier) {
  source('R/utils_ckan.R', local = TRUE)
  source(file.path('datasets', id, 'preparation-api.R'), local = TRUE)
  archive <- file.path('datasets', id, 'snapshots', date, 'source-api.zip')
  stopifnot(identical(digest::digest(file = archive, algo = 'sha256'),
    trimws(readLines(paste0(archive, '.sha256'))[1])))
  extrait <- tempfile(); dir.create(extrait)
  on.exit(unlink(extrait, recursive = TRUE), add = TRUE)
  utils::unzip(archive, exdir = extrait)
  fichier <- file.path(extrait, 'donnees-api.csv')
  old <- Sys.getenv('DB_OFFLINE', unset = NA_character_)
  on.exit(if (is.na(old)) Sys.unsetenv('DB_OFFLINE') else Sys.setenv(DB_OFFLINE = old), add = TRUE)
  Sys.setenv(DB_OFFLINE = 'true')
  ckan_datastore_download(resource_id, fichier)
  verifier(get(preparer)(fichier))
}
verifier_api('qualite-air', '20261110T152954Z', 'cebea532-a9e0-4a39-8c2d-54f33d937c73',
  'preparer_air_api', function(x) stopifnot(nrow(x) == 245L,
    sum(x$station_sans_date_fermeture) == 50L, !anyDuplicated(x$station_id)))
verifier_api('niveaux-eau-inondation', '20261110T152955Z', '9433786e-5bed-4bc3-a9b9-f9efae4a6b77',
  'preparer_niveaux_api', function(x) stopifnot(nrow(x) == 1669L,
    min(x$date_obs) == as.Date('2017-04-30'), max(x$date_obs) == as.Date('2026-04-27')))
message('Stations et niveaux : copies API et données des activités vérifiées.')
