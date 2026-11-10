# Conserver la table d'activité et l'empreinte de sa préparation.
library(readr)
library(jsonlite)
library(digest)
enregistrer_requetes_api <- function(fichier, dossier, provenance) {
  table <- preparer_requetes_api(fichier)
  dir.create(dossier, recursive = TRUE, showWarnings = FALSE)
  sortie <- file.path(dossier, 'table-activite.csv')
  candidat <- tempfile(tmpdir = dossier); on.exit(unlink(candidat), add = TRUE)
  readr::write_csv(table, candidat, na = 'NA')
  if (file.exists(sortie)) {
    if (!identical(digest::digest(file = candidat, algo = 'sha256'), digest::digest(file = sortie, algo = 'sha256')))
      stop('La table existante diffère de cette reconstruction.', call. = FALSE)
  } else if (!file.rename(candidat, sortie)) stop('Impossible de conserver la table.', call. = FALSE)
  jsonlite::write_json(list(source = provenance, fichier_prepare = basename(sortie),
    sha256_prepare = digest::digest(file = sortie, algo = 'sha256'),
    sha256_preparation = digest::digest(file = 'datasets/requetes-311/preparation-api.R', algo = 'sha256'),
    lignes = nrow(table), colonnes = names(table)), file.path(dossier, 'preparation.json'),
    auto_unbox = TRUE, pretty = TRUE)
  Sys.setenv(DB_REQUETES_311_SNAPSHOT = sortie)
  message('Table préparée : ', sortie, '\nElle sera utilisée dans cette session R.',
    '\nPour la réutiliser dans une nouvelle session :\n',
    'Sys.setenv(DB_REQUETES_311_SNAPSHOT = ', encodeString(sortie, quote = '"'), ')')
  invisible(sortie)
}
