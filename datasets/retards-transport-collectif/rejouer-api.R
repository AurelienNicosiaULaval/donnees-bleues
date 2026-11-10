# Reconstruire le résumé de l'accès à partir des métadonnées CKAN datées incluses.
library(jsonlite)
library(readr)
library(digest)
library(dplyr)
source('R/utils_downloads.R')
source('datasets/retards-transport-collectif/preparation-api.R')
source('datasets/retards-transport-collectif/enregistrer-api.R')
rejouer_retards <- function() {
  archive <- 'datasets/retards-transport-collectif/snapshots/20261110T182250Z/source-api.zip'
  if (!identical(digest::digest(file=archive,algo='sha256'),trimws(readLines(paste0(archive,'.sha256'))[1])))
    stop('Archive de métadonnées altérée.',call.=FALSE)
  chemins <- utils::unzip(archive,list=TRUE)$Name
  if (any(grepl('(^/|(^|/)\\.\\.(/|$))',chemins))) stop('Chemin ZIP invalide.',call.=FALSE)
  extrait <- tempfile('retards-api-');dir.create(extrait);on.exit(unlink(extrait,recursive=TRUE),add=TRUE)
  utils::unzip(archive,exdir=extrait)
  fichier <- file.path(extrait,'package-api.json')
  provenance <- jsonlite::read_json(paste0(fichier,'.source.json'))
  ancien <- Sys.getenv('DB_OFFLINE',unset=NA_character_)
  on.exit(if(is.na(ancien)) Sys.unsetenv('DB_OFFLINE') else Sys.setenv(DB_OFFLINE=ancien),add=TRUE)
  Sys.setenv(DB_OFFLINE='true');download_source(provenance$source_url,fichier)
  enregistrer_retards_api(fichier,'data/raw/rejeu-api/retards-transport-collectif/20261110T182250Z',provenance)
}
rejouer_retards()
