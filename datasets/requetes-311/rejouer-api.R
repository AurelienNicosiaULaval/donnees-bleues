# Refaire l'activité depuis l'échantillon API daté inclus, sans connexion.
library(jsonlite)
library(readr)
library(digest)
library(dplyr)
library(stringr)
source('datasets/requetes-311/preparation-api.R')
source('datasets/requetes-311/enregistrer-api.R')
rejouer_requetes_api <- function() {
  archive <- 'datasets/requetes-311/snapshots/20261110T181619Z/source-api.zip'
  if (!identical(digest::digest(file = archive, algo = 'sha256'), trimws(readLines(paste0(archive, '.sha256'))[1])))
    stop('Archive de l’échantillon 311 altérée.', call. = FALSE)
  chemins <- utils::unzip(archive, list = TRUE)$Name
  if (any(grepl('(^/|(^|/)\\.\\.(/|$))', chemins))) stop('Chemin ZIP invalide.', call. = FALSE)
  extrait <- tempfile('requetes-api-'); dir.create(extrait); on.exit(unlink(extrait, recursive = TRUE), add = TRUE)
  utils::unzip(archive, exdir = extrait)
  fichier <- file.path(extrait, 'echantillon-api.csv')
  provenance <- jsonlite::read_json(file.path(extrait, 'provenance-api.json'))
  if (!identical(digest::digest(file = fichier, algo = 'sha256'), provenance$sha256_echantillon))
    stop('Échantillon 311 altéré.', call. = FALSE)
  message('Dernière date de création dans les demandes API parcourues : ', provenance$date_creation_max_population,
    '. Vérifier la couverture temporelle avant interprétation.')
  enregistrer_requetes_api(fichier, 'data/raw/rejeu-api/requetes-311/20261110T181619Z', provenance)
}
rejouer_requetes_api()
