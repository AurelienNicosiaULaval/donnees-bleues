# Conserver le résumé documentaire et l'empreinte des métadonnées CKAN.
library(readr)
library(jsonlite)
library(digest)
enregistrer_retards_api <- function(fichier, dossier, provenance) {
  table <- preparer_retards_api(fichier)
  dir.create(dossier, recursive=TRUE, showWarnings=FALSE)
  sortie <- file.path(dossier, 'table-activite.csv')
  candidat <- tempfile(tmpdir=dossier); on.exit(unlink(candidat), add=TRUE)
  readr::write_csv(table, candidat, na='NA')
  if (file.exists(sortie)) {
    if (!identical(digest::digest(file=candidat,algo='sha256'), digest::digest(file=sortie,algo='sha256')))
      stop('Le résumé existant diffère de cette reconstruction.', call.=FALSE)
  } else if (!file.rename(candidat,sortie)) stop('Impossible de conserver le résumé.', call.=FALSE)
  jsonlite::write_json(list(source=provenance, fichier_prepare=basename(sortie),
    sha256_prepare=digest::digest(file=sortie,algo='sha256'),
    sha256_preparation=digest::digest(file='datasets/retards-transport-collectif/preparation-api.R',algo='sha256')),
    file.path(dossier,'preparation.json'),auto_unbox=TRUE,pretty=TRUE)
  Sys.setenv(DB_RETARDS_METADATA_SNAPSHOT=sortie)
  message('Résumé préparé : ',sortie,'\nIl sera utilisé dans cette session R.',
    '\nPour le réutiliser dans une nouvelle session :\n',
    'Sys.setenv(DB_RETARDS_METADATA_SNAPSHOT = ', encodeString(sortie, quote='"'), ')')
  invisible(sortie)
}
