# Préparer et conserver le résultat ainsi que les empreintes des neuf sources.
library(jsonlite)
library(readr)
library(digest)
enregistrer_etablissements_api <- function(fichiers, dossier, provenance) {
  table <- preparer_etablissements_api(fichiers)
  dir.create(dossier, recursive = TRUE, showWarnings = FALSE)
  sortie <- file.path(dossier, 'table-activite.csv')
  candidat <- tempfile(tmpdir = dossier)
  on.exit(unlink(candidat), add = TRUE)
  readr::write_csv(table, candidat, na = 'NA')
  if (file.exists(sortie)) {
    if (!identical(digest::digest(file = candidat, algo = 'sha256'), digest::digest(file = sortie, algo = 'sha256')))
      stop('La table déjà présente diffère de cette reconstruction.', call. = FALSE)
  } else if (!file.rename(candidat, sortie)) stop('Impossible de conserver la table.', call. = FALSE)
  jsonlite::write_json(list(sources = provenance, fichier_prepare = basename(sortie),
    sha256_prepare = digest::digest(file = sortie, algo = 'sha256'),
    preparation = 'datasets/etablissements-enseignement/preparation-api.R',
    sha256_preparation = digest::digest(file = 'datasets/etablissements-enseignement/preparation-api.R', algo = 'sha256'),
    lignes = nrow(table), colonnes = names(table)), file.path(dossier, 'preparation.json'),
    auto_unbox = TRUE, pretty = TRUE)
  Sys.setenv(DB_ETABLISSEMENTS_SNAPSHOT = sortie)
  message('Table préparée : ', sortie, '\nLes activités utiliseront cette copie dans cette session R.',
    '\nPour la réutiliser dans une nouvelle session :\n',
    'Sys.setenv(DB_ETABLISSEMENTS_SNAPSHOT = ', encodeString(sortie, quote = '"'), ')')
  invisible(sortie)
}
