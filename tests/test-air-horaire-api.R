# Reproduire un résumé journalier depuis la réponse API enregistrée.
verifier_air_horaire_api <- function() {
  source('R/utils_ckan.R', local = TRUE)
  source('datasets/qualite-air-horaire/preparation-api.R', local = TRUE)
  archive <- 'datasets/qualite-air-horaire/snapshots/20261110T154506Z/source-api.zip'
  stopifnot(identical(digest::digest(file = archive, algo = 'sha256'),
    trimws(readLines(paste0(archive, '.sha256'))[1])))
  dossier <- tempfile(); dir.create(dossier)
  on.exit(unlink(dossier, recursive = TRUE), add = TRUE)
  utils::unzip(archive, exdir = dossier)
  fichier <- file.path(dossier, 'donnees-api.csv')
  ancien <- Sys.getenv('DB_OFFLINE', unset = NA_character_)
  on.exit(if (is.na(ancien)) Sys.unsetenv('DB_OFFLINE') else Sys.setenv(DB_OFFLINE = ancien), add = TRUE)
  Sys.setenv(DB_OFFLINE = 'true')
  ckan_datastore_download('370a6be4-1530-4c2b-92f3-0a308224f284', fichier)
  x <- preparer_air_horaire_api(fichier)
  stopifnot(nrow(x) == 46723L, dplyr::n_distinct(x$station_id) == 42L,
    dplyr::n_distinct(x$contaminant_source) == 11L)
  brut <- readr::read_csv(fichier, col_select = c('Station', 'Date_Heure', 'PM2.5-T640'),
    col_types = readr::cols(Date_Heure = readr::col_character()), show_col_types = FALSE)
  fin <- as.POSIXct(brut$Date_Heure, tz = 'Etc/GMT+5')
  jour <- as.Date(fin - 1, tz = 'Etc/GMT+5')
  valeurs <- brut[['PM2.5-T640']][brut$Station == '10200 - Radisson' & jour == as.Date('2025-06-04')]
  resultat <- x[x$station_id == '10200' & x$date == as.Date('2025-06-04') & x$contaminant_source == 'PM2.5-T640', ]
  stopifnot(length(valeurs) == 24L, nrow(resultat) == 1L,
    resultat$n_heures_valides == sum(!is.na(valeurs)),
    isTRUE(all.equal(resultat$moyenne, mean(valeurs, na.rm = TRUE))))
  message('Air horaire : copie API et moyenne journalière indépendante vérifiées.')
}
verifier_air_horaire_api()
