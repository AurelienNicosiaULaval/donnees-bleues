# Recharger la table de comptes conservée; le fichier individuel SAAQ n’est pas inclus.
library(jsonlite)
library(readr)
library(digest)
source('R/utils_downloads.R')
rejouer_parc <- function() {
  archive <- 'datasets/vehicules-canada-2025/snapshots/20261110T200805Z/source-api.zip'
  if (!identical(digest::digest(file = archive, algo = 'sha256'), trimws(readLines(paste0(archive, '.sha256'))[1])))
    stop('Archive SAAQ altérée.', call. = FALSE)
  chemins <- utils::unzip(archive, list = TRUE)$Name
  if (any(grepl('(^/|(^|/)\\.\\.(/|$))', chemins))) stop('Chemin ZIP invalide.', call. = FALSE)
  extrait <- tempfile('parc-api-'); dir.create(extrait); on.exit(unlink(extrait, recursive = TRUE), add = TRUE)
  utils::unzip(archive, exdir = extrait)
  meta <- file.path(extrait, 'package.json'); recu <- jsonlite::read_json(paste0(meta, '.source.json'))
  ancien <- Sys.getenv('DB_OFFLINE', unset = NA_character_)
  on.exit(if (is.na(ancien)) Sys.unsetenv('DB_OFFLINE') else Sys.setenv(DB_OFFLINE = ancien), add = TRUE)
  Sys.setenv(DB_OFFLINE = 'true'); download_source(recu$source_url, meta)
  paquet <- jsonlite::read_json(meta); info <- jsonlite::read_json(file.path(extrait, 'provenance-api.json'))
  ressource <- Filter(function(x) identical(x$id, '36e97894-fd4a-46fd-ab89-9e46329d60a9'), paquet$result$resources)
  table <- file.path(extrait, 'parc-activite.csv')
  if (!isTRUE(paquet$success) || length(ressource) != 1L || !identical(ressource[[1]]$url, info$source_url) ||
      !identical(info$source_sha256, '84f57d77dca8eee189c734c79cde757bf0311ebb5d26694278c31b4db7e331f9') ||
      !identical(digest::digest(file = table, algo = 'sha256'), '4fb91d7190b9c6c62d97c2d23168a1c318206a969bfe3d255bc0d1c42cf30dca'))
    stop('Source ou table du parc invalide.', call. = FALSE)
  dossier <- 'data/raw/rejeu-api/vehicules-canada-2025/20261110T200805Z'
  dir.create(dossier, recursive = TRUE, showWarnings = FALSE); sortie <- file.path(dossier, 'parc-activite.csv')
  if (file.exists(sortie) && !identical(digest::digest(file = sortie, algo = 'sha256'), digest::digest(file = table, algo = 'sha256')))
    stop('La table existante diffère de la copie datée.', call. = FALSE)
  if (!file.exists(sortie) && !file.copy(table, sortie)) stop('Copie impossible.', call. = FALSE)
  Sys.setenv(DB_PARC_SAAQ_SNAPSHOT = sortie)
  message('Table du parc chargée : ', sortie, '\nElle sera utilisée dans cette session R.')
}
rejouer_parc()
