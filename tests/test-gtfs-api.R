# Vérifier le fichier GTFS daté, ses arrêts et la mention de provenance RTC.
verifier_gtfs_api <- function() {
  source('R/utils_downloads.R',local=TRUE)
  source('datasets/transport-collectif-gtfs/preparation-api.R',local=TRUE)
  archive <- 'datasets/transport-collectif-gtfs/snapshots/20261110T191550Z/source-api.zip'
  stopifnot(identical(digest::digest(file=archive,algo='sha256'),trimws(readLines(paste0(archive,'.sha256'))[1])))
  dossier <- tempfile();dir.create(dossier);on.exit(unlink(dossier,recursive=TRUE),add=TRUE)
  utils::unzip(archive,exdir=dossier)
  fichiers <- file.path(dossier,c('package-api.json','gtfs-rtc.zip'))
  ancien <- Sys.getenv('DB_OFFLINE',unset=NA_character_)
  on.exit(if(is.na(ancien)) Sys.unsetenv('DB_OFFLINE') else Sys.setenv(DB_OFFLINE=ancien),add=TRUE)
  Sys.setenv(DB_OFFLINE='true')
  recus <- lapply(fichiers,function(f) jsonlite::read_json(paste0(f,'.source.json')))
  for(i in seq_along(fichiers)) download_source(recus[[i]]$source_url,fichiers[[i]])
  paquet <- jsonlite::read_json(fichiers[[1]])
  ressource <- Filter(function(x) identical(x$id,'52f3e1db-992b-42ac-87b9-bb4be1de6111'),paquet$result$resources)
  stopifnot(isTRUE(paquet$success),length(ressource)==1L,identical(ressource[[1]]$url,recus[[2]]$source_url),
    identical(recus[[2]]$details$rtc_updated_date,'2026-11-09'))
  x <- preparer_gtfs_api(fichiers[[2]])
  stopifnot(nrow(x)==4318L, !anyDuplicated(x$stop_id),
    sum(x$wheelchair_boarding==0L,na.rm=TRUE)==2423L,
    sum(x$wheelchair_boarding==1L,na.rm=TRUE)==1895L,
    any(grepl('9 novembre 2026',readLines('datasets/transport-collectif-gtfs/CITATION-RTC-API.md',warn=FALSE),fixed=TRUE)))
  message('GTFS : métadonnées, arrêts, date et attribution RTC vérifiés.')
}
verifier_gtfs_api()
