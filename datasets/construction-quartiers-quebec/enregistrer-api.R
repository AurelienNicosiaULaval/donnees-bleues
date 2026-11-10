# Conserver l'agrégat et les informations nécessaires pour refaire les calculs spatiaux.
library(readr)
library(jsonlite)
library(digest)
library(sf)
enregistrer_construction_api <- function(fichiers, dossier, provenance) {
  table <- preparer_construction_api(fichiers)
  dir.create(dossier, recursive = TRUE, showWarnings = FALSE)
  sortie <- file.path(dossier, 'table-activite.csv')
  candidat <- tempfile(tmpdir = dossier); on.exit(unlink(candidat), add = TRUE)
  readr::write_csv(table, candidat, na = 'NA')
  if (file.exists(sortie)) {
    if (!identical(digest::digest(file = candidat, algo = 'sha256'), digest::digest(file = sortie, algo = 'sha256')))
      stop('La table existante diffère de cette reconstruction; vérifier les versions spatiales.', call. = FALSE)
  } else if (!file.rename(candidat, sortie)) stop('Impossible de conserver la table.', call. = FALSE)
  jsonlite::write_json(list(sources = provenance, fichier_prepare = basename(sortie),
    sha256_prepare = digest::digest(file = sortie, algo = 'sha256'),
    sha256_preparation = digest::digest(file = 'datasets/construction-quartiers-quebec/preparation-api.R', algo = 'sha256'),
    version_R = as.character(getRversion()), version_sf = as.character(utils::packageVersion('sf')),
    versions_spatiales = as.list(sf::sf_extSoftVersion()), lignes = nrow(table), colonnes = names(table)),
    file.path(dossier, 'preparation.json'), auto_unbox = TRUE, pretty = TRUE)
  Sys.setenv(DB_CONSTRUCTION_SNAPSHOT = sortie)
  message('Table préparée : ', sortie, '\nElle sera utilisée dans cette session R.',
    '\nPour la réutiliser dans une nouvelle session :\n',
    'Sys.setenv(DB_CONSTRUCTION_SNAPSHOT = ', encodeString(sortie, quote = '"'), ')')
  invisible(sortie)
}
