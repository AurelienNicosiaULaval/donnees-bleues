# Reconstruire l'instantané GBFS inclus sans connexion.
library(jsonlite)
library(readr)
library(digest)
library(dplyr)
source('R/utils_downloads.R')
source('datasets/bixi/preparation-api.R')
source('datasets/bixi/enregistrer-api.R')
rejouer_bixi <- function() {
  archive <- 'datasets/bixi/snapshots/20261110T160032Z/source-api.zip'
  if (!identical(digest::digest(file = archive, algo = 'sha256'), trimws(readLines(paste0(archive, '.sha256'))[1])))
    stop('Archive GBFS altérée.', call. = FALSE)
  chemins <- utils::unzip(archive, list = TRUE)$Name
  if (any(grepl('(^/|(^|/)\\.\\.(/|$))', chemins))) stop('Chemin ZIP invalide.', call. = FALSE)
  extrait <- tempfile('bixi-gbfs-'); dir.create(extrait); on.exit(unlink(extrait, recursive = TRUE), add = TRUE)
  utils::unzip(archive, exdir = extrait)
  fichiers <- file.path(extrait, c('gbfs.json','station_information.json','station_status.json'))
  sources <- lapply(fichiers, function(f) jsonlite::read_json(paste0(f, '.source.json')))
  ancien <- Sys.getenv('DB_OFFLINE', unset = NA_character_)
  on.exit(if (is.na(ancien)) Sys.unsetenv('DB_OFFLINE') else Sys.setenv(DB_OFFLINE = ancien), add = TRUE)
  Sys.setenv(DB_OFFLINE = 'true')
  for (i in seq_along(fichiers)) download_source(sources[[i]]$source_url, fichiers[i])
  enregistrer_bixi_api(fichiers[2], fichiers[3], 'data/raw/rejeu-api/bixi/20261110T160032Z', sources)
}
rejouer_bixi()
