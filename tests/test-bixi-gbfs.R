# Vérifier la reconstruction locale d'un instantané GBFS et ses indicateurs.
verifier_bixi_gbfs <- function() {
  racine <- normalizePath('.')
  dossier <- tempfile(); dir.create(dossier)
  on.exit({setwd(racine); unlink(dossier, recursive = TRUE)}, add = TRUE)
  utils::unzip(file.path(racine, 'assets/classroom/bixi.zip'), exdir = dossier)
  setwd(dossier)
  ancien <- Sys.getenv('DB_OFFLINE', unset = NA_character_)
  ancien_choix <- Sys.getenv('DB_BIXI_SNAPSHOT', unset = NA_character_)
  on.exit({if (is.na(ancien)) Sys.unsetenv('DB_OFFLINE') else Sys.setenv(DB_OFFLINE = ancien)
    if (is.na(ancien_choix)) Sys.unsetenv('DB_BIXI_SNAPSHOT') else Sys.setenv(DB_BIXI_SNAPSHOT = ancien_choix)}, add = TRUE)
  Sys.setenv(DB_OFFLINE = 'true')
  source('datasets/bixi/rejouer-api.R', local = TRUE)
  x <- readr::read_csv(Sys.getenv('DB_BIXI_SNAPSHOT'), show_col_types = FALSE)
  avec_capacite <- x$capacity > 0 & !is.na(x$num_bikes_available)
  stopifnot(nrow(x) == 1112L, !anyDuplicated(x$station_id),
    isTRUE(all.equal(x$taux_occupation[avec_capacite],
      x$num_bikes_available[avec_capacite] / x$capacity[avec_capacite])),
    min(x$last_reported_datetime, na.rm = TRUE) >= as.POSIXct('2009-05-01', tz = 'UTC'))
  message('BIXI : flux GBFS datés et ratios de disponibilité vérifiés.')
}
verifier_bixi_gbfs()
