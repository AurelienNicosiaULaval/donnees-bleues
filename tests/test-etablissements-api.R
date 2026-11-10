# Vérifier le rejeu des neuf ressources et leurs unités respectives.
verifier_etablissements_api <- function() {
  racine <- normalizePath('.')
  dossier <- tempfile(); dir.create(dossier)
  on.exit({setwd(racine); unlink(dossier, recursive = TRUE)}, add = TRUE)
  utils::unzip(file.path(racine, 'assets/classroom/etablissements-enseignement.zip'), exdir = dossier)
  setwd(dossier)
  ancien <- Sys.getenv('DB_OFFLINE', unset = NA_character_)
  ancien_choix <- Sys.getenv('DB_ETABLISSEMENTS_SNAPSHOT', unset = NA_character_)
  on.exit({if (is.na(ancien)) Sys.unsetenv('DB_OFFLINE') else Sys.setenv(DB_OFFLINE = ancien)
    if (is.na(ancien_choix)) Sys.unsetenv('DB_ETABLISSEMENTS_SNAPSHOT') else Sys.setenv(DB_ETABLISSEMENTS_SNAPSHOT = ancien_choix)}, add = TRUE)
  Sys.setenv(DB_OFFLINE = 'true')
  source('datasets/etablissements-enseignement/rejouer-api.R', local = TRUE)
  x <- readr::read_csv(Sys.getenv('DB_ETABLISSEMENTS_SNAPSHOT'), show_col_types = FALSE)
  stopifnot(nrow(x) == 14077L, dplyr::n_distinct(x$source_resource) == 9L,
    sum(x$source_resource == 'public_ecole') == 5457L,
    all(x$unit_kind[x$source_resource == 'public_ecole'] == 'Lien école-immeuble'),
    all(x$unit_kind[x$source_resource == 'public_immeuble'] == 'Immeuble'))
  message('Établissements : neuf copies API et unités vérifiées.')
}
verifier_etablissements_api()
