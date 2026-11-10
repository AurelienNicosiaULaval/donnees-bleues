# Vérifier le raccordement des mesures API aux aires de drainage datées.
verifier_rivieres_api <- function() {
  racine <- normalizePath('.')
  dossier <- tempfile(); dir.create(dossier)
  on.exit({setwd(racine); unlink(dossier, recursive = TRUE)}, add = TRUE)
  utils::unzip(file.path(racine, 'assets/classroom/suivi-rivieres-fleuve.zip'), exdir = dossier)
  setwd(dossier)
  ancien <- Sys.getenv('DB_OFFLINE', unset = NA_character_)
  ancien_choix <- Sys.getenv('DB_RIVIERES_SNAPSHOT', unset = NA_character_)
  on.exit({if (is.na(ancien)) Sys.unsetenv('DB_OFFLINE') else Sys.setenv(DB_OFFLINE = ancien)
    if (is.na(ancien_choix)) Sys.unsetenv('DB_RIVIERES_SNAPSHOT') else Sys.setenv(DB_RIVIERES_SNAPSHOT = ancien_choix)}, add = TRUE)
  Sys.setenv(DB_OFFLINE = 'true')
  source('datasets/suivi-rivieres-fleuve/rejouer-api.R', local = TRUE)
  x <- readr::read_csv(Sys.getenv('DB_RIVIERES_SNAPSHOT'), show_col_types = FALSE)
  stopifnot(nrow(x) == 6990L, dplyr::n_distinct(x$no_bqma) == 935L,
    any(!is.na(x$pc_agricole)), any(x$bv_n1m == 'Richelieu, Rivière', na.rm = TRUE))
  message('Rivières : mesures API et référence datée des aires de drainage vérifiées.')
}
verifier_rivieres_api()
