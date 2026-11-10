# Refaire la table d'arrêts à partir des métadonnées et du GTFS RTC datés inclus.
library(jsonlite)
library(curl)
library(readr)
library(digest)
library(dplyr)
source('R/utils_downloads.R')
source('datasets/transport-collectif-gtfs/preparation-api.R')
source('datasets/transport-collectif-gtfs/enregistrer-api.R')
rejouer_gtfs <- function() {
  archive <- 'datasets/transport-collectif-gtfs/snapshots/20261110T191550Z/source-api.zip'
  if (!identical(digest::digest(file=archive,algo='sha256'),trimws(readLines(paste0(archive,'.sha256'))[1])))
    stop('Archive GTFS altérée.',call.=FALSE)
  chemins <- utils::unzip(archive,list=TRUE)$Name
  if (any(grepl('(^/|(^|/)\\.\\.(/|$))',chemins))) stop('Chemin ZIP invalide.',call.=FALSE)
  extrait <- tempfile('gtfs-api-');dir.create(extrait);on.exit(unlink(extrait,recursive=TRUE),add=TRUE)
  utils::unzip(archive,exdir=extrait)
  metadata <- file.path(extrait,'package-api.json');gtfs <- file.path(extrait,'gtfs-rtc.zip')
  rmeta <- jsonlite::read_json(paste0(metadata,'.source.json'));rgtfs <- jsonlite::read_json(paste0(gtfs,'.source.json'))
  ancien <- Sys.getenv('DB_OFFLINE',unset=NA_character_)
  on.exit(if(is.na(ancien)) Sys.unsetenv('DB_OFFLINE') else Sys.setenv(DB_OFFLINE=ancien),add=TRUE)
  Sys.setenv(DB_OFFLINE='true');download_source(rmeta$source_url,metadata);download_source(rgtfs$source_url,gtfs)
  paquet <- jsonlite::read_json(metadata)
  r <- Filter(function(x) identical(x$id,'52f3e1db-992b-42ac-87b9-bb4be1de6111'),paquet$result$resources)
  if (!isTRUE(paquet$success) || length(r)!=1L || !identical(r[[1]]$url,rgtfs$source_url))
    stop('La ressource GTFS ne correspond pas aux métadonnées.',call.=FALSE)
  enregistrer_gtfs_api(metadata,gtfs,'data/raw/rejeu-api/transport-collectif-gtfs/20261110T191550Z')
}
rejouer_gtfs()
