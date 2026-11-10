# Refaire les jointures spatiales à partir des trois copies API distribuées.
verifier_construction_api <- function() {
  racine <- normalizePath('.')
  dossier <- tempfile(); dir.create(dossier)
  on.exit({setwd(racine); unlink(dossier, recursive = TRUE)}, add = TRUE)
  utils::unzip(file.path(racine,'assets/classroom/construction-quartiers-quebec.zip'),exdir=dossier)
  setwd(dossier)
  ancien <- Sys.getenv('DB_OFFLINE',unset=NA_character_)
  ancien_choix <- Sys.getenv('DB_CONSTRUCTION_SNAPSHOT',unset=NA_character_)
  on.exit({if (is.na(ancien)) Sys.unsetenv('DB_OFFLINE') else Sys.setenv(DB_OFFLINE=ancien)
    if (is.na(ancien_choix)) Sys.unsetenv('DB_CONSTRUCTION_SNAPSHOT') else Sys.setenv(DB_CONSTRUCTION_SNAPSHOT=ancien_choix)}, add=TRUE)
  Sys.setenv(DB_OFFLINE='true')
  source('datasets/construction-quartiers-quebec/rejouer-api.R',local=TRUE)
  x <- readr::read_csv(Sys.getenv('DB_CONSTRUCTION_SNAPSHOT'),show_col_types=FALSE)
  stopifnot(nrow(x)==35L, !anyDuplicated(x$id_quartier),
    sum(x$nombre_permis) >= 70000, sum(x$nombre_permis) <= 71444,
    sum(x$nombre_batiments) >= 200000, sum(x$nombre_batiments) <= 284987,
    all(x$superficie_quartier_km2 > 0),
    isTRUE(all.equal(x$permis_par_km2, x$nombre_permis/x$superficie_quartier_km2)))
  message('Construction : trois sources API et agrégats spatiaux vérifiés.')
}
verifier_construction_api()
