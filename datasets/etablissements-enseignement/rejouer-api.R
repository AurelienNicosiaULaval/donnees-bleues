# Refaire la table à partir des neuf réponses API conservées, sans connexion.
library(jsonlite)
library(httr2)
library(readr)
library(digest)
library(dplyr)
source('R/utils_downloads.R')
source('R/utils_ckan.R')
source('datasets/etablissements-enseignement/ressources-api.R')
source('datasets/etablissements-enseignement/preparation-api.R')
source('datasets/etablissements-enseignement/enregistrer-api.R')
rejouer_etablissements <- function() {
  temporaire <- tempfile('etablissements-api-'); dir.create(temporaire)
  on.exit(unlink(temporaire, recursive = TRUE), add = TRUE)
  ancien <- Sys.getenv('DB_OFFLINE', unset = NA_character_)
  on.exit(if (is.na(ancien)) Sys.unsetenv('DB_OFFLINE') else Sys.setenv(DB_OFFLINE = ancien), add = TRUE)
  Sys.setenv(DB_OFFLINE = 'true')
  fichiers <- setNames(lapply(ressources_api, function(r) {
    empreinte <- trimws(readLines(paste0(r$archive, '.sha256'), warn = FALSE)[1])
    if (!identical(digest::digest(file = r$archive, algo = 'sha256'), empreinte))
      stop('Archive API altérée : ', r$cle, call. = FALSE)
    chemins <- utils::unzip(r$archive, list = TRUE)$Name
    if (any(grepl('(^/|(^|/)\\.\\.(/|$))', chemins))) stop('Chemin ZIP invalide.', call. = FALSE)
    cible <- file.path(temporaire, r$cle); dir.create(cible)
    utils::unzip(r$archive, exdir = cible)
    fichier <- file.path(cible, 'donnees-api.csv')
    ckan_datastore_download(r$ressource, fichier)
    fichier
  }), vapply(ressources_api, function(r) r$cle, character(1)))
  provenance <- lapply(fichiers, function(f) jsonlite::read_json(paste0(f, '.source.json')))
  dossier <- 'data/raw/rejeu-api/etablissements-enseignement/20261110T155734Z'
  enregistrer_etablissements_api(fichiers, dossier, provenance)
}
rejouer_etablissements()
