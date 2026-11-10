# Acquérir les flux GBFS repérés dans la source BIXI liée par Données Québec.
library(jsonlite)
library(readr)
library(digest)
library(dplyr)
source('R/utils_downloads.R')
source('datasets/bixi/preparation-api.R')
source('datasets/bixi/enregistrer-api.R')
dossier <- file.path('data/raw/api/bixi', format(Sys.time(), '%Y%m%dT%H%M%SZ', tz = 'UTC'))
dir.create(dossier, recursive = TRUE, showWarnings = FALSE)
decouverte <- file.path(dossier, 'gbfs.json')
download_source('https://gbfs.velobixi.com/gbfs/gbfs.json', decouverte)
flux <- jsonlite::read_json(decouverte)$data$fr$feeds
for (nom in c('station_information', 'station_status')) {
  urls <- vapply(Filter(function(x) identical(x$name, nom), flux), function(x) x$url, character(1))
  if (length(urls) != 1L || !startsWith(urls, 'https://gbfs.velobixi.com/'))
    stop('Flux BIXI absent ou inattendu : ', nom, call. = FALSE)
  download_source(urls, file.path(dossier, paste0(nom, '.json')))
}
fichiers <- file.path(dossier, c('gbfs.json','station_information.json','station_status.json'))
sources <- lapply(fichiers, function(f) jsonlite::read_json(paste0(f, '.source.json')))
enregistrer_bixi_api(fichiers[2], fichiers[3], dossier, sources)
