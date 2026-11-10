# Préparer les arrêts utilisés par les activités à partir du GTFS RTC conservé.
library(readr)
library(dplyr)
preparer_gtfs_api <- function(fichier) {
  entrees <- utils::unzip(fichier,list=TRUE)$Name
  if (sum(entrees=='stops.txt')!=1L || any(grepl('(^/|(^|/)\\.\\.(/|$))',entrees)))
    stop('Archive GTFS invalide ou fichier des arrêts absent.',call.=FALSE)
  dossier <- tempfile('arrets-gtfs-');dir.create(dossier);on.exit(unlink(dossier,recursive=TRUE),add=TRUE)
  utils::unzip(fichier,files='stops.txt',exdir=dossier)
  arrets <- readr::read_csv(file.path(dossier,'stops.txt'),
    col_types=readr::cols(.default=readr::col_character(),stop_lat=readr::col_double(),
      stop_lon=readr::col_double(),wheelchair_boarding=readr::col_integer(),stop_code=readr::col_integer()),
    show_col_types=FALSE)
  readr::stop_for_problems(arrets)
  champs <- c('stop_id','stop_name','stop_lat','stop_lon','wheelchair_boarding','stop_code')
  if (!nrow(arrets) || !all(champs %in% names(arrets)) || anyNA(arrets$stop_id) || anyDuplicated(arrets$stop_id))
    stop('Structure ou identifiants GTFS invalides.',call.=FALSE)
  arrets |>
    arrange(stop_code,stop_id) |>
    transmute(stop_id,stop_name,latitude=stop_lat,longitude=stop_lon,wheelchair_boarding,
      wheelchair_boarding_label=case_when(wheelchair_boarding==0L ~ 'Information non disponible',
        wheelchair_boarding==1L ~ 'Accessible selon le codage GTFS',
        wheelchair_boarding==2L ~ 'Non accessible selon le codage GTFS',TRUE ~ 'Code non documenté'))
}
