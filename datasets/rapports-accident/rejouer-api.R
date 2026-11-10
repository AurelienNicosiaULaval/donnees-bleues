# Reconstruire la table des activités depuis la projection datée du CSV officiel.
library(jsonlite)
library(readr)
library(digest)
library(dplyr)
library(stringr)
source('R/utils_downloads.R')
source('datasets/rapports-accident/preparation-api.R')
source('datasets/rapports-accident/enregistrer-api.R')
rejouer_accidents <- function() {
  archive <- 'datasets/rapports-accident/snapshots/20261110T192219Z/source-api.zip'
  if (!identical(digest::digest(file=archive,algo='sha256'),trimws(readLines(paste0(archive,'.sha256'))[1])))
    stop('Archive des accidents altérée.',call.=FALSE)
  chemins <- utils::unzip(archive,list=TRUE)$Name
  if (any(grepl('(^/|(^|/)\\.\\.(/|$))',chemins))) stop('Chemin ZIP invalide.',call.=FALSE)
  extrait <- tempfile('accidents-api-');dir.create(extrait);on.exit(unlink(extrait,recursive=TRUE),add=TRUE)
  utils::unzip(archive,exdir=extrait)
  metadata <- file.path(extrait,'package.json');recu_meta <- jsonlite::read_json(paste0(metadata,'.source.json'))
  ancien <- Sys.getenv('DB_OFFLINE',unset=NA_character_)
  on.exit(if(is.na(ancien)) Sys.unsetenv('DB_OFFLINE') else Sys.setenv(DB_OFFLINE=ancien),add=TRUE)
  Sys.setenv(DB_OFFLINE='true');download_source(recu_meta$source_url,metadata)
  paquet <- jsonlite::read_json(metadata)
  ressource <- Filter(function(x) identical(x$id,'be702e5c-a25e-421e-b00d-0360c73525f1'),paquet$result$resources)
  provenance <- jsonlite::read_json(file.path(extrait,'provenance-api.json'))
  projection <- file.path(extrait,'projection-api.csv')
  if (!isTRUE(paquet$success) || length(ressource)!=1L || !identical(ressource[[1]]$url,provenance$source_url) ||
      !identical(provenance$source_sha256,'17fc60a26fb8ed8cc0fac871a7e4efc30cda95b93500e7a7f8213ba45008232a') ||
      !identical(digest::digest(file=projection,algo='sha256'),provenance$projection_sha256))
    stop('Projection ou provenance des accidents invalide.',call.=FALSE)
  enregistrer_accidents_api(projection,provenance,'data/raw/rejeu-api/rapports-accident/20261110T192219Z')
}
rejouer_accidents()
