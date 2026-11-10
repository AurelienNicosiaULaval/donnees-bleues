# Recharger les 200 arbres préparés; le GeoPackage complet n’est pas inclus.
library(jsonlite)
library(readr)
library(digest)
source('R/utils_downloads.R')
rejouer_arbres_forestiers <- function() {
  archive <- 'datasets/arbres-quebec/snapshots/20261110T200718Z/source-api.zip'
  if (!identical(digest::digest(file = archive, algo = 'sha256'), trimws(readLines(paste0(archive, '.sha256'))[1])))
    stop('Archive de provenance altérée.', call. = FALSE)
  chemins <- utils::unzip(archive, list = TRUE)$Name
  if (any(grepl('(^/|(^|/)\\.\\.(/|$))', chemins))) stop('Chemin ZIP invalide.', call. = FALSE)
  extrait <- tempfile('arbres-api-'); dir.create(extrait); on.exit(unlink(extrait, recursive = TRUE), add = TRUE)
  utils::unzip(archive, exdir = extrait)
  meta <- file.path(extrait, 'package.json'); recu <- jsonlite::read_json(paste0(meta, '.source.json'))
  ancien <- Sys.getenv('DB_OFFLINE', unset = NA_character_)
  on.exit(if (is.na(ancien)) Sys.unsetenv('DB_OFFLINE') else Sys.setenv(DB_OFFLINE = ancien), add = TRUE)
  Sys.setenv(DB_OFFLINE = 'true'); download_source(recu$source_url, meta)
  paquet <- jsonlite::read_json(meta); info <- jsonlite::read_json(file.path(extrait, 'provenance-api.json'))
  ressource <- Filter(function(x) identical(x$id, 'd09ae743-f3ca-4bfc-90d5-65c2614a679e'), paquet$result$resources)
  table <- file.path(extrait, 'arbres-activite.csv')
  if (!isTRUE(paquet$success) || length(ressource) != 1L || !identical(ressource[[1]]$url, info$source_url) ||
      !identical(info$source_sha256, '45e66eeb95ea7f3e47aa0840a8a263c1cc2862ccf0b33fd5e007e353ca48174d') ||
      !identical(digest::digest(file = table, algo = 'sha256'), '1af11ff0fc824f35286987928f0423441540ece1badb674f347ab05db07d4ccf'))
    stop('Source ou table forestière invalide.', call. = FALSE)
  dossier <- 'data/raw/rejeu-api/arbres-quebec/20261110T200718Z'
  dir.create(dossier, recursive = TRUE, showWarnings = FALSE); sortie <- file.path(dossier, 'arbres-activite.csv')
  if (file.exists(sortie) && !identical(digest::digest(file = sortie, algo = 'sha256'), digest::digest(file = table, algo = 'sha256')))
    stop('La table existante diffère de la copie datée.', call. = FALSE)
  if (!file.exists(sortie) && !file.copy(table, sortie)) stop('Copie impossible.', call. = FALSE)
  Sys.setenv(DB_ARBRES_FOREST_SNAPSHOT = sortie)
  message('Table forestière chargée : ', sortie, '\nElle sera utilisée dans cette session R.')
}
rejouer_arbres_forestiers()
